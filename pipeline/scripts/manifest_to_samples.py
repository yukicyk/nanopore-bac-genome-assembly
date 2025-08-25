#!/usr/bin/env python3
# File: pipeline/scripts/manifest_to_samples.py
# Version: 2.0 
"""
Builds the initial workflow samples.tsv from comprehensive Run Manifests.
This script now strictly adheres to the project's Data Contract.
"""
import argparse
import csv
import glob
import os
import sys
from typing import List, Dict

# --- DATA CONTRACT ---
# These are the official column headers we will use everywhere.
OUTPUT_HEADERS = [
    "sample_id", "platform", "ont_reads", "illumina_r1", "illumina_r2",
    "biosample", "srrs", "barcode"
]

def sniff_reader(fh):
    # (Sniffer logic remains the same as in the previous version)
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
    # (Normalization logic remains the same)
    p = (p or "").strip().lower()
    if p in {"oxford_nanopore", "oxford-nanopore", "nanopore"}:
        p = "ont"
    if p in {"hiseq", "miseq", "nextseq", "novaseq"}:
        p = "illumina"
    if p in {"ont", "illumina"}:
        return p
    return default_platform

def read_manifest(path: str) -> List[Dict[str, str]]:
    # (Reading logic remains the same)
    with open(path, "r", newline="", encoding="utf-8") as fh:
        reader = sniff_reader(fh)
        rows = []
        for row in reader:
            norm = { (k or "").strip(): (v or "").strip() for k, v in row.items() }
            if not any(norm.values()):
                continue
            rows.append(norm)
        return rows

def main():
    ap = argparse.ArgumentParser(description="Convert run manifests to the workflow's samples.tsv format.")
    ap.add_argument("--manifests_glob", required=True, help="Glob for manifest files, e.g., 'data/manifests/*.tsv'")
    ap.add_argument("--out", required=True, help="Output path for workflow samples TSV (e.g., config/samples.tsv)")
    ap.add_argument("--default-platform", choices=["ont", "illumina"], default="ont", help="Platform to assign if not present/recognized")
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

            # This script only handles initial creation, so platform is ont or illumina, not hybrid.
            plat = normalize_platform(r.get("platform", ""), args.default_platform)

            # --- CHANGED: Map manifest columns to Data Contract columns ---
            out_row = {
                "sample_id": sid,
                "platform": plat,
                "ont_reads": (r.get("read_path") or r.get("fastq_path") or r.get("fastq_guess") or "") if plat == "ont" else "",
                "illumina_r1": (r.get("read_path_r1") or r.get("fastq_r1") or r.get("r1") or "") if plat == "illumina" else "",
                "illumina_r2": (r.get("read_path_r2") or r.get("fastq_r2") or r.get("r2") or "") if plat == "illumina" else "",
                "biosample": (r.get("biosample_accession") or r.get("biosample") or "").strip(),
                "srrs": (r.get("srr_accession") or r.get("srrs") or "").strip(),
                "barcode": (r.get("barcode_id") or r.get("barcode") or "").strip(),
            }
            collected.append(out_row)

    # Deduplicate by sample_id, keeping first occurrence
    seen = set()
    deduped: List[Dict[str, str]] = []
    for r in collected:
        if r["sample_id"] in seen:
            continue
        seen.add(r["sample_id"])
        deduped.append(r)

    if not deduped:
        print("No valid sample rows found.", file=sys.stderr)
        return 1

    # --- CHANGED: Write output with the exact Data Contract headers ---
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "w", newline="", encoding="utf-8") as outfh:
        writer = csv.DictWriter(outfh, fieldnames=OUTPUT_HEADERS, delimiter="\t", extrasaction='ignore')
        writer.writeheader()
        writer.writerows(deduped)

    print(f"Wrote {args.out} with {len(deduped)} samples.", file=sys.stderr)
    return 0

if __name__ == "__main__":
    sys.exit(main())