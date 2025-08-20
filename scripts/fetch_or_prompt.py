#!/usr/bin/env python3
"""
fetch_or_prompt.py

Resolve and fetch FASTQ reads for samples from SRA using BioSample or explicit SRR lists.

- Reads an input TSV with columns:
  required: sample_id, platform (ont|illumina)
  optional: biosample (e.g., SAMNxxxxxx), srrs (SRA accession, if more than one comma-separated, e.g. SRX9276211,SRX9276210), read_path (for ont), read_path_r1 (for illumina R1), read_path_r2 (for illumina R2), barcode
- If read_path/read_path_r1/read_path_r2 already point to existing files, they are kept (unless --force).
- Otherwise:
  - If srrs provided, use them.
  - Else, resolve SRR(s) from ENA by BioSample and platform.
  - Download each SRR via fasterq-dump (threads), gzip, and merge to sample-level files:
      ONT:  outdir/{sample_id}.fastq.gz
      ILL:  outdir/{sample_id}_R1.fastq.gz and outdir/{sample_id}_R2.fastq.gz
- Writes an updated TSV with resolved paths and a resolved_srrs column.

Usage:
  python fetch_or_prompt.py --samples config/samples.tsv --out config/samples.resolved.tsv \
      --threads 8 --non-interactive --skip-existing --outdir data/raw
"""

from __future__ import annotations

import argparse
import csv
import os
import re
import shutil
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

try:
    import requests
except Exception:
    requests = None  # We can fall back to curl if needed.

# ---------- Helpers ----------

def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)

def run(cmd: List[str], check: bool = True, env: Optional[Dict[str, str]] = None):
    eprint("[cmd]", " ".join(cmd))
    return subprocess.run(cmd, check=check, env=env)

def ensure_parent(path: Path):
    path.parent.mkdir(parents=True, exist_ok=True)

def which(prog: str) -> Optional[str]:
    return shutil.which(prog)

def safe_int(x, default=0):
    try:
        return int(x)
    except Exception:
        return default

# ---------- ENA resolution ----------

ENA_READ_RUN_FIELDS = [
    "run_accession",
    "instrument_platform",
    "library_layout",
    "library_strategy",
    "submitted_format",
    "fastq_ftp",
    "submitted_ftp",
]

ENA_BASE = "https://www.ebi.ac.uk/ena/portal/api/filereport"

def ena_query_runs_by_biosample(biosample: str) -> List[Dict[str, str]]:
    """
    Query ENA read_run table by BioSample accession. Returns list of rows as dicts.
    """
    params = {
        "accession": biosample,
        "result": "read_run",
        "fields": ",".join(ENA_READ_RUN_FIELDS),
        "download": "true",
    }
    url = ENA_BASE
    text = None
    if requests is not None:
        r = requests.get(url, params=params, timeout=30)
        if r.status_code != 200:
            eprint(f"[ena] HTTP {r.status_code}: {r.text[:200]}")
            return []
        text = r.text
    else:
        # Fallback via curl
        if not which("curl"):
            eprint("[ena] requests not available and curl not found.")
            return []
        curl_cmd = ["curl", "-sS", "--get", url]
        for k, v in params.items():
            curl_cmd += ["--data-urlencode", f"{k}={v}"]
        cp = subprocess.run(curl_cmd, capture_output=True, text=True)
        if cp.returncode != 0:
            eprint(f"[ena] curl failed: {cp.stderr}")
            return []
        text = cp.stdout

    lines = [l for l in text.splitlines() if l.strip()]
    if not lines:
        return []
    header = lines[0].split("\t")
    rows = []
    for line in lines[1:]:
        parts = line.split("\t")
        row = {h: (parts[i] if i < len(parts) else "") for i, h in enumerate(header)}
        rows.append(row)
    return rows

def platform_matches(row: Dict[str, str], want: str, strict: bool = True) -> bool:
    """
    want: 'ont' or 'illumina'
    strict True: require instrument_platform exact match; False: looser contains checks.
    """
    inst = (row.get("instrument_platform") or "").strip().upper()
    if strict:
        if want == "ont":
            return inst == "OXFORD_NANOPORE"
        elif want == "illumina":
            return inst == "ILLUMINA"
        else:
            return False
    # loose
    if want == "ont":
        return "NANOPORE" in inst or "OXFORD" in inst
    if want == "illumina":
        return "ILLUMINA" in inst
    return False

def layout_for_illumina(row: Dict[str, str]) -> str:
    return (row.get("library_layout") or "").strip().upper()  # PAIRED or SINGLE

def resolve_srrs(biosample: str, platform: str, strict_platform: bool = True) -> List[str]:
    """
    Resolve run_accession(s) from ENA for a given biosample and platform.
    """
    if not biosample:
        return []
    rows = ena_query_runs_by_biosample(biosample)
    srrs = []
    for r in rows:
        if platform_matches(r, platform, strict=strict_platform):
            acc = r.get("run_accession", "").strip()
            if acc:
                srrs.append(acc)
    # Deduplicate, preserve order
    seen = set()
    out = []
    for a in srrs:
        if a not in seen:
            seen.add(a)
            out.append(a)
    return out

# ---------- Downloaders and merging ----------

def fasterq_dump_available() -> bool:
    return which("fasterq-dump") is not None

def prefetch_available() -> bool:
    return which("prefetch") is not None

def pigz_available() -> bool:
    return which("pigz") is not None

def gzip_cat_concat(src_files: List[Path], dest_gz: Path) -> bool:
    """
    Concatenate plain fastq files and compress to dest_gz using pigz (preferred) or gzip.
    Returns True on success.
    """
    ensure_parent(dest_gz)
    if dest_gz.exists():
        dest_gz.unlink()
    if pigz_available():
        # pigz -c file1 file2 > dest
        cmd = ["pigz", "-c"] + [str(p) for p in src_files]
        with open(dest_gz, "wb") as fh:
            cp = subprocess.run(cmd, stdout=fh)
            return cp.returncode == 0
    else:
        # gzip -c concatenated stream
        # Use shell for cat to avoid loading into Python memory.
        cat_cmd = ["bash", "-lc", "cat " + " ".join(map(lambda p: f"'{str(p)}'", src_files)) + " | gzip -c > " + f"'{str(dest_gz)}'"]
        cp = subprocess.run(cat_cmd)
        return cp.returncode == 0

def download_srr(srr: str, workdir: Path, threads: int, illumina_split: bool) -> List[Path]:
    """
    Download SRR into workdir using fasterq-dump.
    Returns list of produced fastq paths (plain, not gz).
    """
    workdir.mkdir(parents=True, exist_ok=True)
    outdir = workdir
    args = ["fasterq-dump", srr, "-O", str(outdir), "--threads", str(threads)]
    if illumina_split:
        args.append("--split-files")
    run(args)
    # Collect produced fastqs: fasterq-dump outputs .fastq for ONT, and _1.fastq/_2.fastq for paired
    produced = []
    if illumina_split:
        c1 = outdir / f"{srr}_1.fastq"
        c2 = outdir / f"{srr}_2.fastq"
        if c1.exists():
            produced.append(c1)
        if c2.exists():
            produced.append(c2)
        # Single-end Illumina could produce only one file without suffix; handle also SRR.fastq
        c0 = outdir / f"{srr}.fastq"
        if c0.exists() and not c1.exists() and not c2.exists():
            produced.append(c0)
    else:
        c = outdir / f"{srr}.fastq"
        if c.exists():
            produced.append(c)
    return produced

def merge_runs_ont(sample_id: str, srrs: List[str], tmpdir: Path, outdir: Path, threads: int) -> Optional[Path]:
    """
    Download and merge ONT runs to outdir/{sample_id}.fastq.gz
    """
    target = outdir / f"{sample_id}.fastq.gz"
    if target.exists() and target.stat().st_size > 0:
        return target
    # Download each SRR, collect .fastq, then compress+concat
    produced: List[Path] = []
    for srr in srrs:
        files = download_srr(srr, tmpdir, threads=threads, illumina_split=False)
        if not files:
            eprint(f"[fetch] {sample_id}: no files produced by fasterq-dump for {srr}")
            continue
        produced.extend(files)
    produced = [p for p in produced if p.exists() and p.stat().st_size > 0]
    if not produced:
        eprint(f"[fetch] {sample_id}: no ONT fastq files to merge.")
        return None
    ok = gzip_cat_concat(produced, target)
    if not ok:
        eprint(f"[fetch] {sample_id}: failed to write {target}")
        return None
    # Cleanup temp files
    for p in produced:
        try:
            p.unlink()
        except Exception:
            pass
    return target

def merge_runs_illumina(sample_id: str, srrs: List[str], tmpdir: Path, outdir: Path, threads: int) -> Tuple[Optional[Path], Optional[Path]]:
    """
    Download and merge Illumina runs to outdir/{sample_id}_R1.fastq.gz and _R2.fastq.gz
    Handles both paired-end and single-end; if single-end only, R2 may be None.
    """
    r1_list: List[Path] = []
    r2_list: List[Path] = []
    se_list: List[Path] = []  # single-end files if any

    for srr in srrs:
        files = download_srr(srr, tmpdir, threads=threads, illumina_split=True)
        # Classify files
        for f in files:
            name = f.name
            if name.endswith("_1.fastq"):
                r1_list.append(f)
            elif name.endswith("_2.fastq"):
                r2_list.append(f)
            elif name.endswith(".fastq"):
                se_list.append(f)

    out_r1 = outdir / f"{sample_id}_R1.fastq.gz"
    out_r2 = outdir / f"{sample_id}_R2.fastq.gz"

    produced_any = False

    # If we have paired data, merge R1 and R2 separately
    if r1_list:
        ok1 = gzip_cat_concat(r1_list, out_r1)
        produced_any = produced_any or ok1
    # R2 may be optional (some submissions mark single-end)
    if r2_list:
        ok2 = gzip_cat_concat(r2_list, out_r2)
        produced_any = produced_any or ok2

    # For purely single-end Illumina data
    if not r1_list and not r2_list and se_list:
        ok = gzip_cat_concat(se_list, out_r1)
        produced_any = produced_any or ok
        out_r2 = None

    # Cleanup tmp fastqs
    for p in r1_list + r2_list + se_list:
        try:
            p.unlink()
        except Exception:
            pass

    if not produced_any:
        return None, None
    # If R1 missing (edge case), set None
    if not out_r1.exists() or out_r1.stat().st_size == 0:
        out_r1 = None
    if out_r2 is not None and (not out_r2.exists() or out_r2.stat().st_size == 0):
        out_r2 = None
    return out_r1, out_r2

# ---------- I/O ----------

REQ_COLS = ["sample_id", "platform"]
OPT_COLS = ["biosample", "srrs", "read_path", "read_path_r1", "read_path_r2", "barcode"]

@dataclass
class SampleRow:
    sample_id: str
    platform: str  # "ont" or "illumina"
    biosample: str = ""
    srrs: List[str] = field(default_factory=list)
    read_path: str = ""        # ONT
    read_path_r1: str = ""     # Illumina
    read_path_r2: str = ""     # Illumina
    barcode: str = ""
    resolved_srrs: List[str] = field(default_factory=list)
    note: str = ""

    @classmethod
    def from_dict(cls, d: Dict[str, str]) -> "SampleRow":
        srrs_raw = (d.get("srrs") or "").strip()
        srrs = [x.strip() for x in re.split(r"[;,]\s*|\s+", srrs_raw) if x.strip()] if srrs_raw else []
        platform = (d.get("platform") or "").strip().lower()
        return cls(
            sample_id=(d.get("sample_id") or "").strip(),
            platform=platform,
            biosample=(d.get("biosample") or d.get("biosample_accession") or "").strip(),
            srrs=srrs,
            read_path=(d.get("read_path") or "").strip(),
            read_path_r1=(d.get("read_path_r1") or "").strip(),
            read_path_r2=(d.get("read_path_r2") or "").strip(),
            barcode=(d.get("barcode") or "").strip(),
        )

    def to_dict(self) -> Dict[str, str]:
        d = {
            "sample_id": self.sample_id,
            "platform": self.platform,
            "biosample": self.biosample,
            "srrs": ",".join(self.srrs) if self.srrs else "",
            "read_path": self.read_path,
            "read_path_r1": self.read_path_r1,
            "read_path_r2": self.read_path_r2,
            "barcode": self.barcode,
            "resolved_srrs": ",".join(self.resolved_srrs) if self.resolved_srrs else "",
            "note": self.note,
        }
        return d

def read_tsv(p: Path) -> List[Dict[str, str]]:
    with p.open("r", newline="") as fh:
        sniffer = csv.Sniffer()
        sample = fh.read(2048)
        fh.seek(0)
        dialect = sniffer.sniff(sample, delimiters="\t,")
        reader = csv.DictReader(fh, dialect=dialect)
        rows = [dict(r) for r in reader]
    return rows

def write_tsv(p: Path, rows: List[SampleRow]):
    ensure_parent(p)
    # Determine full header union
    header = ["sample_id", "platform", "biosample", "srrs", "read_path", "read_path_r1", "read_path_r2", "barcode", "resolved_srrs", "note"]
    with p.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=header, dialect="excel-tab", delimiter="\t")
        w.writeheader()
        for r in rows:
            w.writerow(r.to_dict())

# ---------- Main workflow ----------

def process_sample(
    s: SampleRow,
    outdir: Path,
    threads: int,
    strict_platform: bool,
    non_interactive: bool,
    skip_existing: bool,
    force: bool,
) -> SampleRow:
    """
    Returns updated SampleRow with paths/srrs filled in or note explaining failure.
    """
    platform = s.platform
    if platform not in ("ont", "illumina"):
        s.note = f"unsupported platform: {platform}"
        return s

    # If paths already exist and --skip-existing, keep them
    if skip_existing and not force:
        if platform == "ont" and s.read_path:
            if Path(s.read_path).exists() and Path(s.read_path).stat().st_size > 0:
                s.note = "kept existing read_path"
                return s
        if platform == "illumina" and (s.read_path_r1 or s.read_path_r2):
            ok1 = s.read_path_r1 and Path(s.read_path_r1).exists() and Path(s.read_path_r1).stat().st_size > 0
            ok2 = (not s.read_path_r2) or (Path(s.read_path_r2).exists() and Path(s.read_path_r2).stat().st_size > 0)
            if ok1 and ok2:
                s.note = "kept existing read_path_r1/_r2"
                return s

    # Determine SRRs to fetch
    resolved_srrs: List[str] = []
    if s.srrs:
        resolved_srrs = s.srrs
    else:
        if not s.biosample:
            s.note = "no biosample and no srrs"
            return s
        eprint(f"[fetch] {s.sample_id}: resolving SRRs from ENA for {s.biosample} (platform={platform})")
        resolved_srrs = resolve_srrs(s.biosample, platform, strict_platform=strict_platform)

    if not resolved_srrs:
        s.note = "no runs found for biosample/platform"
        return s

    s.resolved_srrs = resolved_srrs

    if not fasterq_dump_available():
        s.note = "fasterq-dump not found on PATH"
        return s

    # Prep output targets
    outdir.mkdir(parents=True, exist_ok=True)
    tmpdir = Path(tempfile.mkdtemp(prefix=f"{s.sample_id}_sra_"))
    try:
        if platform == "ont":
            target = outdir / f"{s.sample_id}.fastq.gz"
            if target.exists() and target.stat().st_size > 0 and skip_existing and not force:
                s.read_path = str(target)
                s.note = "kept existing merged ONT"
                return s
            res = merge_runs_ont(s.sample_id, resolved_srrs, tmpdir=tmpdir, outdir=outdir, threads=threads)
            if res is None:
                s.note = "ONT merge failed"
                return s
            s.read_path = str(res)
            s.note = "ONT merged"
            return s

        # Illumina
        r1, r2 = merge_runs_illumina(s.sample_id, resolved_srrs, tmpdir=tmpdir, outdir=outdir, threads=threads)
        if r1 is None and r2 is None:
            s.note = "Illumina merge failed"
            return s
        s.read_path_r1 = str(r1) if r1 else ""
        s.read_path_r2 = str(r2) if r2 else ""
        s.note = "Illumina merged"
        return s
    finally:
        # Cleanup tmpdir
        try:
            shutil.rmtree(tmpdir, ignore_errors=True)
        except Exception:
            pass

def main():
    ap = argparse.ArgumentParser(description="Resolve/download FASTQs by BioSample or SRR list, merging multiple runs.")
    ap.add_argument("--samples", required=True, help="Input TSV (samples.tsv)")
    ap.add_argument("--out", required=True, help="Output TSV (samples.resolved.tsv)")
    ap.add_argument("--threads", type=int, default=4, help="Threads for fasterq-dump")
    ap.add_argument("--non-interactive", action="store_true", help="Do not prompt; fail silently on missing runs")
    ap.add_argument("--skip-existing", action="store_true", help="Keep existing read_path files if present")
    ap.add_argument("--force", action="store_true", help="Re-download and overwrite even if outputs exist")
    ap.add_argument("--outdir", default="data/raw", help="Directory for output FASTQs")
    ap.add_argument("--platform-filter", choices=["strict", "loose"], default="strict",
                    help="Platform matching strictness when resolving SRRs via ENA")
    args = ap.parse_args()

    samples_tsv = Path(args.samples)
    out_tsv = Path(args.out)
    outdir = Path(args.outdir)
    strict_platform = args.platform_filter == "strict"

    if not samples_tsv.exists():
        eprint(f"[fetch] input TSV missing: {samples_tsv}")
        sys.exit(1)

    rows_raw = read_tsv(samples_tsv)
    # Validate headers
    missing = [c for c in REQ_COLS if c not in rows_raw[0]]
    if missing:
        eprint(f"[fetch] missing required columns: {missing}")
        sys.exit(1)

    rows: List[SampleRow] = [SampleRow.from_dict(r) for r in rows_raw]

    # Process
    updated: List[SampleRow] = []
    for s in rows:
        # Normalize platform values
        s.platform = s.platform.lower().strip()
        if s.platform not in ("ont", "illumina"):
            s.note = f"unsupported platform: {s.platform}"
            updated.append(s)
            continue

        # If interactive and nothing found, we could prompt here, but we default to non-interactive behavior.
        s_out = process_sample(
            s=s,
            outdir=outdir,
            threads=args.threads,
            strict_platform=strict_platform,
            non_interactive=args.non_interactive,
            skip_existing=args.skip_existing,
            force=args.force,
        )
        # Log summary line
        if s_out.platform == "ont":
            eprint(f"[fetch] {s_out.sample_id} ({s_out.platform}) -> {s_out.read_path or 'NONE'} | SRRs: {','.join(s_out.resolved_srrs) or '[]'} | {s_out.note}")
        else:
            eprint(f"[fetch] {s_out.sample_id} ({s_out.platform}) -> R1={s_out.read_path_r1 or 'NONE'} R2={s_out.read_path_r2 or 'NONE'} | SRRs: {','.join(s_out.resolved_srrs) or '[]'} | {s_out.note}")
        updated.append(s_out)

    write_tsv(out_tsv, updated)
    eprint(f"[fetch] Wrote updated TSV: {out_tsv}")

if __name__ == "__main__":
    main()