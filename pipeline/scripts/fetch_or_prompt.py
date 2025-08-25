#!/usr/bin/env python3
# File: pipeline/scripts/fetch_or_prompt.py
# Version: 2.1 (Robust I/O)
"""
Resolves the samples.tsv by fetching data from SRA if local paths are missing.
Writes a final samples.resolved.tsv with all local paths populated and the
'platform' column correctly set to 'ont', 'illumina', or 'hybrid'.
This script is the final preparation step before running the Snakemake workflow.
"""
from __future__ import annotations
import argparse, csv, os, re, shutil, subprocess, sys, tempfile
from dataclasses import dataclass, field, fields
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# --- DEPENDENCY CHECK ---
try:
    import requests
except ImportError:
    sys.exit("ERROR: The 'requests' library is required. Please install it: pip install requests")

# --- HELPER FUNCTIONS ---
def eprint(*args, **kwargs): print(*args, file=sys.stderr, **kwargs)
def run(cmd: List[str], check: bool = True, env: Optional[Dict[str, str]] = None): eprint("[cmd]", " ".join(cmd)); return subprocess.run(cmd, check=check, env=env)
def ensure_parent(path: Path): path.parent.mkdir(parents=True, exist_ok=True)
def which(prog: str) -> Optional[str]: return shutil.which(prog)

# --- ENA/SRA QUERY LOGIC ---
ENA_READ_RUN_FIELDS = ["run_accession", "instrument_platform", "library_layout"]
ENA_BASE = "https://www.ebi.ac.uk/ena/portal/api/filereport"
def ena_query_runs_by_biosample(biosample: str) -> List[Dict[str, str]]:
    if not biosample: return []
    params = {"accession": biosample, "result": "read_run", "fields": ",".join(ENA_READ_RUN_FIELDS), "download": "true"}
    try:
        r = requests.get(ENA_BASE, params=params, timeout=30)
        r.raise_for_status() # Raise an exception for bad status codes (4xx or 5xx)
    except requests.RequestException as e:
        eprint(f"Warning: ENA query failed for {biosample}: {e}")
        return []
    lines = [l for l in r.text.splitlines() if l.strip()]
    if not lines or len(lines) < 2: return []
    header = lines[0].split("\t")
    return [dict(zip(header, l.split("\t"))) for l in lines[1:]]

def platform_matches(row: Dict[str, str], want: str) -> bool:
    inst = (row.get("instrument_platform") or "").strip().upper()
    if want == "ont": return inst == "OXFORD_NANOPORE"
    if want == "illumina": return inst == "ILLUMINA"
    return False

def resolve_srrs(biosample: str, platform: str) -> List[str]:
    rows = ena_query_runs_by_biosample(biosample)
    return [r["run_accession"] for r in rows if platform_matches(r, platform) and r.get("run_accession")]

# --- DATA DOWNLOAD LOGIC ---
def fasterq_dump_available() -> bool: return which("fasterq-dump") is not None
def pigz_available() -> bool: return which("pigz") is not None

def gzip_cat_concat(src_files: List[Path], dest_gz: Path) -> bool:
    ensure_parent(dest_gz)
    if dest_gz.exists(): dest_gz.unlink()
    compressor = "pigz" if pigz_available() else "gzip"
    # Use a temporary file for the concatenated output before compressing
    with tempfile.NamedTemporaryFile(mode='wb', delete=False) as tmp_cat:
        for src in src_files:
            with open(src, 'rb') as f_in:
                shutil.copyfileobj(f_in, tmp_cat)
    # Now compress the concatenated file
    with open(tmp_cat.name, 'rb') as f_in, open(dest_gz, 'wb') as f_out:
        proc = subprocess.run([compressor], stdin=f_in, stdout=f_out)
    os.unlink(tmp_cat.name)
    return proc.returncode == 0

def download_srr(srr: str, workdir: Path, threads: int, illumina_split: bool) -> List[Path]:
    args = ["fasterq-dump", srr, "-O", str(workdir), "--threads", str(threads), "--temp", str(workdir)]
    if illumina_split: args.append("--split-files")
    run(args)
    # Return paths that were actually created
    if illumina_split:
        return [p for p in [workdir / f"{srr}_1.fastq", workdir / f"{srr}_2.fastq"] if p.exists()]
    else:
        return [p for p in [workdir / f"{srr}.fastq"] if p.exists()]

def merge_runs_ont(sample_id: str, srrs: List[str], tmpdir: Path, outdir: Path, threads: int) -> Optional[Path]:
    target = outdir / f"{sample_id}.ont.fastq.gz"
    produced = [f for srr in srrs for f in download_srr(srr, tmpdir, threads, False)]
    if not produced: return None
    if gzip_cat_concat(produced, target): return target
    return None

def merge_runs_illumina(sample_id: str, srrs: List[str], tmpdir: Path, outdir: Path, threads: int) -> Tuple[Optional[Path], Optional[Path]]:
    out_r1 = outdir / f"{sample_id}.illumina.R1.fastq.gz"
    out_r2 = outdir / f"{sample_id}.illumina.R2.fastq.gz"
    r1_list, r2_list = [], []
    for srr in srrs:
        downloaded = download_srr(srr, tmpdir, threads, True)
        for f in downloaded:
            if f.name.endswith("_1.fastq"): r1_list.append(f)
            elif f.name.endswith("_2.fastq"): r2_list.append(f)
    if r1_list: gzip_cat_concat(r1_list, out_r1)
    if r2_list: gzip_cat_concat(r2_list, out_r2)
    return (out_r1 if out_r1.exists() else None, out_r2 if out_r2.exists() else None)

# --- DATA CONTRACT I/O (ROBUST VERSION) ---
@dataclass
class SampleRow:
    sample_id: str
    platform: str
    ont_reads: str = ""
    illumina_r1: str = ""
    illumina_r2: str = ""
    biosample: str = ""
    srrs: str = ""
    barcode: str = ""
    note: str = ""

    @classmethod
    def from_dict(cls, d: Dict[str, str]) -> "SampleRow":
        # Only use keys that are actual fields in this dataclass
        field_names = {f.name for f in fields(cls)}
        filtered_dict = {k: (v or "").strip() for k, v in d.items() if k in field_names}
        return cls(**filtered_dict)

    def to_dict(self) -> Dict[str, str]:
        return {f.name: getattr(self, f.name) for f in fields(self)}

def read_tsv(p: Path) -> List[SampleRow]:
    with p.open("r", newline="", encoding="utf-8") as fh:
        # DictReader correctly handles out-of-order columns
        reader = csv.DictReader(fh, delimiter="\t")
        return [SampleRow.from_dict(row) for row in reader]

def write_tsv(p: Path, rows: List[SampleRow]):
    ensure_parent(p)
    # The header is defined *only* by the SampleRow dataclass fields. This is the key fix.
    header = [f.name for f in fields(SampleRow)]
    with p.open("w", newline="", encoding="utf-8") as fh:
        writer = csv.DictWriter(fh, fieldnames=header, delimiter="\t")
        writer.writeheader()
        writer.writerows([r.to_dict() for r in rows])

# --- MAIN WORKFLOW ---
def process_sample(s: SampleRow, outdir: Path, threads: int) -> SampleRow:
    # If a path is already given, we trust it and do nothing.
    if s.ont_reads and Path(s.ont_reads).exists():
        s.note = "Kept existing ONT path."
    elif s.platform in ['ont', 'hybrid']:
        srrs_to_fetch = [x.strip() for x in s.srrs.split(',') if x.strip()] or resolve_srrs(s.biosample, 'ont')
        if srrs_to_fetch:
            eprint(f"[{s.sample_id}] Fetching ONT reads for SRRs: {srrs_to_fetch}")
            with tempfile.TemporaryDirectory(prefix=f"{s.sample_id}_ont_") as tmp:
                path = merge_runs_ont(s.sample_id, srrs_to_fetch, Path(tmp), outdir, threads)
                s.ont_reads = str(path) if path else ""
                s.note += "ONT fetched; "
        else:
            s.note += "ONT SRRs not found; "

    if s.illumina_r1 and Path(s.illumina_r1).exists():
        s.note += "Kept existing Illumina path."
    elif s.platform in ['illumina', 'hybrid']:
        srrs_to_fetch = [x.strip() for x in s.srrs.split(',') if x.strip()] or resolve_srrs(s.biosample, 'illumina')
        if srrs_to_fetch:
            eprint(f"[{s.sample_id}] Fetching Illumina reads for SRRs: {srrs_to_fetch}")
            with tempfile.TemporaryDirectory(prefix=f"{s.sample_id}_ill_") as tmp:
                r1, r2 = merge_runs_illumina(s.sample_id, srrs_to_fetch, Path(tmp), outdir, threads)
                s.illumina_r1 = str(r1) if r1 else ""
                s.illumina_r2 = str(r2) if r2 else ""
                s.note += "Illumina fetched; "
        else:
            s.note += "Illumina SRRs not found; "

    # Final platform resolution based on what files actually exist
    has_ont = bool(s.ont_reads and Path(s.ont_reads).exists())
    has_illumina = bool(s.illumina_r1 and Path(s.illumina_r1).exists())

    if has_ont and has_illumina:
        s.platform = "hybrid"
    elif has_ont:
        s.platform = "ont"
    elif has_illumina:
        s.platform = "illumina"
    else:
        s.platform = "none" # Explicitly mark as having no data
        if not s.note: s.note = "ERROR: No valid read paths found or fetched."

    return s

def main():
    ap = argparse.ArgumentParser(description="Resolves sample sheet by fetching data from SRA.")
    ap.add_argument("--samples", required=True, help="Input TSV (config/samples.tsv)")
    ap.add_argument("--out", required=True, help="Output TSV (config/samples.resolved.tsv)")
    ap.add_argument("--outdir", default="data/raw", help="Directory for output FASTQs")
    ap.add_argument("--threads", type=int, default=4, help="Threads for fasterq-dump")
    args = ap.parse_args()

    # Check for required tools
    if not fasterq_dump_available():
        eprint("ERROR: 'fasterq-dump' not found in PATH. Please install SRA-Tools.")
        sys.exit(1)

    samples_tsv = Path(args.samples)
    if not samples_tsv.exists():
        eprint(f"Input TSV missing: {samples_tsv}"); sys.exit(1)

    initial_rows = read_tsv(samples_tsv)
    final_rows = [process_sample(s, Path(args.outdir), args.threads) for s in initial_rows]
    write_tsv(Path(args.out), final_rows)
    eprint(f"Wrote resolved TSV to: {args.out}")

if __name__ == "__main__":
    main()