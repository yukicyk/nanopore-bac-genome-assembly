#!/usr/bin/env python3
"""
Build workflow samples.tsv (Schema B) from a comprehensive Run Manifest & Metadata (Schema A+).

Now supports Illumina paired reads with read_path_r1/read_path_r2.

Purpose
- Convert a per-run manifest (wet-lab + run metadata) into the minimal
  workflow samples table that serves as input to the workflow in Snakemake.

Schemas
- Input: Schema A+ (Run Manifest & Metadata; TSV/CSV)
  Required columns:
    - sample_id
  Optional but supported (mapped when present):
    - platform                     -> platform (expects 'ont' or 'illumina' if provided)
    - barcode_id                   -> barcode
    - biosample_accession          -> biosample_accession (often blank at wet-lab stage)
    - fastq_path or fastq_guess    -> read_path (absolute or relative path to .fastq(.gz))
  All other columns are ignored by this script (they remain in your manifest archive).

- Output: Schema B (Workflow Samples; TSV)
  Columns (written in this exact order):
    - sample_id (required)
    - platform (required; 'ont' or 'illumina'; may be filled by --default-platform)
    - read_path (may be empty; used directly if provided)
    - read_path_r1      (Illumina; may be empty)
    - read_path_r2      (Illumina; may be empty)
    - biosample_accession (optional; used by fetch if read_path empty)
    - barcode (optional)

Behavior
- Reads all manifest files matching --manifests_glob (tab, comma, or semicolon delimited).
- Normalizes and selects columns for Schema B.
- If platform is missing or unrecognized, uses --default-platform.
- If fastq_path or fastq_guess are present, copies to read_path.
- Deduplicates rows by sample_id (first occurrence wins).
- Writes TSV to --out.

Enhancements:
- If read_path is not provided but demux_output_path and barcode_id are present, infer a per-sample FASTQ path using common ONT Dorado/Guppy demultiplexing layouts.

Usage
  python scripts/manifest_to_samples.py \
    --manifests_glob "data/manifests/*.tsv" \
    --out config/samples.tsv \
    --default-platform ont

Options
- --manifests_glob: Glob for input manifest file(s) (Schema A+).
- --out: Output path for Schema B TSV.
- --default-platform: ont or illumina; used when manifest lacks platform.

Requirements
- Python 3.8+

Notes
- biosample_accession is optional in Schema A+ and Schema B. It becomes relevant
  only if you intend to fetch reads from NCBI SRA (when read_path is empty).
"""
# File: scripts/manifest_to_samples.py

import argparse
import csv
import glob
import os
import re
import sys
from typing import List, Dict, Optional

VALID_PLATFORMS = {"ont", "illumina"}

def sniff_reader(fh):
    sample = fh.read(4096)
    fh.seek(0)
    try:
        dialect = csv.Sniffer().sniff(sample, delimiters="\t,;")
    except Exception:
        class _Tab(csv.Dialect):
            delimiter = "\t"
            quotechar = '"'
            doublequote = True
            lineterminator = "\n"
            quoting = csv.QUOTE_MINIMAL
        dialect = _Tab
    return csv.DictReader(fh, dialect=dialect)

def normalize_platform(p: str, default_platform: str) -> str:
    p = (p or "").strip().lower()
    if p in {"oxford_nanopore", "oxford-nanopore", "nanopore"}:
        p = "ont"
    if p in {"hiseq","miseq","nextseq","novaseq"}:
        p = "illumina"
    if p in VALID_PLATFORMS:
        return p
    return default_platform

def read_manifest(path: str) -> List[Dict[str, str]]:
    with open(path, "r", newline="", encoding="utf-8") as fh:
        reader = sniff_reader(fh)
        rows = []
        for row in reader:
            norm = { (k or "").strip(): (v or "").strip() for k, v in row.items() }
            if not any(norm.values()):
                continue
            rows.append(norm)
        return rows

def _infer_fastq_from_demux(demux_dir: str, barcode_id: str) -> Optional[str]:
    """
    Infer a single ONT FASTQ (gz) from demultiplexing outputs for ONT.
    """
    if not demux_dir or not barcode_id:
        return None
    d = os.path.abspath(demux_dir)
    if not os.path.isdir(d):
        return None

    m = re.search(r'(\d+)$', barcode_id)
    num = m.group(1) if m else re.sub(r'\D', '', barcode_id)
    if not num:
        return None
    num2 = num.zfill(2)
    base = f"barcode{num2}"

    candidates = []
    glob_patterns = [
        os.path.join(d, base, "*.fastq.gz"),
        os.path.join(d, base, "fastq_pass", "*.fastq.gz"),
        os.path.join(d, f"{base}.fastq.gz"),
        os.path.join(d, f"{base}_*.fastq.gz"),
        os.path.join(d, base, "reads.fastq.gz"),
    ]
    for pat in glob_patterns:
        candidates.extend(glob.glob(pat))

    candidates = list({os.path.abspath(p) for p in candidates if os.path.isfile(p)})
    if not candidates:
        return None
    if len(candidates) == 1:
        return candidates[0]

    def score(p):
        s = 0
        pl = p.lower()
        if "/fastq_pass/" in pl or pl.endswith("/fastq_pass"):
            s += 10
        size = os.path.getsize(p)
        return (s, size)

    candidates.sort(key=score, reverse=True)
    return candidates[0]

def main():
    ap = argparse.ArgumentParser(description="Convert run manifests (Schema A+) to workflow samples (Schema B), with ONT read_path inference and Illumina R1/R2 support.")
    ap.add_argument("--manifests_glob", required=True, help="Glob for manifest files, e.g., 'data/manifests/*.tsv'")
    ap.add_argument("--out", required=True, help="Output path for workflow samples TSV (Schema B)")
    ap.add_argument("--default-platform", choices=["ont","illumina"], default="ont", help="Platform to assign if not present/recognized")
    args = ap.parse_args()

    paths = sorted(glob.glob(args.manifests_glob))
    if not paths:
        print(f"No manifests matched: {args.manifests_glob}", file=sys.stderr)
        return 1

    collected: List[Dict[str, str]] = []
    for p in paths:
        try:
            rows = read_manifest(p)
        except Exception as e:
            print(f"Error reading {p}: {e}", file=sys.stderr)
            return 1
        for r in rows:
            sid = (r.get("sample_id") or "").strip()
            if not sid:
                continue
            plat = normalize_platform(r.get("platform",""), args.default_platform)

            # ONT single-end path
            read_path = (r.get("read_path") or r.get("fastq_path") or r.get("fastq_guess") or "").strip()
            if not read_path and plat == "ont":
                demux_dir = (r.get("demux_output_path") or r.get("fastq_output_path") or "").strip()
                barcode = (r.get("barcode_id") or r.get("barcode") or "").strip()
                guess = _infer_fastq_from_demux(demux_dir, barcode)
                if guess:
                    read_path = guess

            # Illumina paired-end (if your manifest provides them)
            read_path_r1 = (r.get("read_path_r1") or r.get("fastq_r1") or r.get("r1") or "").strip()
            read_path_r2 = (r.get("read_path_r2") or r.get("fastq_r2") or r.get("r2") or "").strip()

            out = {
                "sample_id": sid,
                "platform": plat,
                "read_path": read_path if plat == "ont" else "",
                "read_path_r1": read_path_r1 if plat == "illumina" else "",
                "read_path_r2": read_path_r2 if plat == "illumina" else "",
                "biosample_accession": (r.get("biosample_accession") or "").strip(),
                "barcode": (r.get("barcode_id") or r.get("barcode") or "").strip(),
            }
            collected.append(out)

    # Deduplicate by sample_id, keeping first occurrence
    seen = set()
    deduped: List[Dict[str, str]] = []
    for r in collected:
        sid = r["sample_id"]
        if sid in seen:
            continue
        seen.add(sid)
        deduped.append(r)

    if not deduped:
        print("No valid rows (sample_id missing).", file=sys.stderr)
        return 1

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    fieldnames = ["sample_id","platform","read_path","read_path_r1","read_path_r2","biosample_accession","barcode"]
    with open(args.out, "w", newline="", encoding="utf-8") as outfh:
        w = csv.DictWriter(outfh, fieldnames=fieldnames, delimiter="\t")
        w.writeheader()
        for r in deduped:
            w.writerow({k: r.get(k, "") for k in fieldnames})

    print(f"Wrote {args.out} with {len(deduped)} samples.", file=sys.stderr)
    return 0

if __name__ == "__main__":
    sys.exit(main())