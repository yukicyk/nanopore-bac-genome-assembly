# ==============================
# File: workflow/rules/io.smk
# ==============================
from pathlib import Path
import os
import json
import subprocess
from typing import Dict, List, Tuple, Optional

# Resolve repo root same way as Snakefile
_env_root = os.environ.get("REPO_ROOT", "")
if _env_root:
    REPO = Path(_env_root).resolve()
else:
    # io.smk is in .../workflow/rules; repo root is two levels up
    REPO = Path(__file__).resolve().parent.parent.parent

DATA_RAW = (REPO / "data" / "raw").resolve()
SCRIPTS_DIR = (REPO / "scripts").resolve()
READ_SAMPLES = (SCRIPTS_DIR / "read_samples_tsv.py").resolve()

print(f"[io.smk] REPO={REPO} DATA_RAW={DATA_RAW} READ_SAMPLES={READ_SAMPLES}")

# Internal cache for rows parsed from the samples table
_SAMPLE_ROWS: Dict[str, Dict] = {}

def _abs(path_like: str) -> str:
    if not path_like:
        return ""
    p = Path(path_like)
    if not p.is_absolute():
        p = (REPO / p).resolve()
    return str(p)

def read_samples(samples_tsv: str) -> List[str]:
    """
    Read the workflow samples table (TSV; tab-delimited) via scripts/read_samples_tsv.py.

    Expected columns (schema; some optional depending on platform):
      - sample_id
      - platform                 (ont | illumina)
      - read_path                (ONT; optional if to be fetched)
      - read_path_r1             (Illumina; optional if to be fetched)
      - read_path_r2             (Illumina; optional if to be fetched)
      - biosample or biosample_accession (optional)
      - srrs                     (optional; comma-separated)
      - barcode                  (optional)

    Returns:
      List of sample_ids in the table (order preserved by the helper script).
    """
    tsv_path = Path(samples_tsv)
    if not tsv_path.is_absolute():
        tsv_path = (REPO / tsv_path).resolve()
    if not tsv_path.exists():
        # Return empty list during parse/planning; rules that require it must depend on resolve_samples.
        return []

    proc = subprocess.run(
        [str(READ_SAMPLES), str(tsv_path)],
        check=True,
        capture_output=True,
        text=True,
    )
    stdout = proc.stdout or "{}"
    try:
        data = json.loads(stdout)
    except json.JSONDecodeError as e:
        raise RuntimeError(f"Failed to parse JSON from {READ_SAMPLES}: {e}\nSTDOUT:\n{stdout}")

    if "error" in data:
        raise ValueError(f"samples.tsv error: {data['error']}")
    rows = data.get("samples", [])
    if not rows:
        raise ValueError(f"No samples found in samples TSV: {tsv_path}")

    # Normalize and cache rows
    global _SAMPLE_ROWS
    _SAMPLE_ROWS = {}
    for row in rows:
        sid = (row.get("sample_id") or "").strip()
        if not sid:
            continue
        platform = (row.get("platform") or "").strip().lower()
        row["platform"] = platform
        # Normalize paths to absolute (if present)
        rp = (row.get("read_path") or "").strip()
        r1 = (row.get("read_path_r1") or "").strip()
        r2 = (row.get("read_path_r2") or "").strip()
        if rp:
            row["read_path"] = _abs(rp)
        if r1:
            row["read_path_r1"] = _abs(r1)
        if r2:
            row["read_path_r2"] = _abs(r2)
        _SAMPLE_ROWS[sid] = row

    return list(_SAMPLE_ROWS.keys())

def get_platform(sample_id: str) -> str:
    row = _SAMPLE_ROWS.get(sample_id)
    if not row:
        raise KeyError(f"Sample not found: {sample_id}")
    return (row.get("platform") or "").strip().lower()

def raw_read_path(sample_id: str) -> str:
    """
    Resolve per-sample raw reads path for ONT samples.

    Resolution:
      - If read_path is set in the TSV:
          * If absolute, return as-is.
          * If relative, resolve relative to REPO.
      - If read_path is empty:
          * Default to data/raw/{sample_id}.fastq.gz under REPO.

    Returns:
      Absolute path as string.
    """
    row = _SAMPLE_ROWS.get(sample_id)
    if not row:
        raise KeyError(f"Sample not found: {sample_id}")
    if (row.get("platform") or "").lower() != "ont":
        raise ValueError(f"raw_read_path called for non-ONT sample: {sample_id} (platform={row.get('platform')})")
    rp = (row.get("read_path") or "").strip()
    if rp:
        return _abs(rp)
    return str((DATA_RAW / f"{sample_id}.fastq.gz").resolve())

def illumina_read_paths(sample_id: str) -> Tuple[Optional[str], Optional[str]]:
    """
    Resolve per-sample Illumina paired-end paths.

    Resolution:
      - If read_path_r1/_r2 set, return absolute versions (r2 may be empty/None for single-end).
      - If missing, default to:
          data/raw/{sample_id}_R1.fastq.gz
          data/raw/{sample_id}_R2.fastq.gz (may not exist for SE)

    Returns:
      (r1_path, r2_path_or_None)
    """
    row = _SAMPLE_ROWS.get(sample_id)
    if not row:
        raise KeyError(f"Sample not found: {sample_id}")
    if (row.get("platform") or "").lower() != "illumina":
        raise ValueError(f"illumina_read_paths called for non-Illumina sample: {sample_id} (platform={row.get('platform')})")

    r1 = (row.get("read_path_r1") or "").strip()
    r2 = (row.get("read_path_r2") or "").strip()

    if not r1:
        r1 = str((DATA_RAW / f"{sample_id}_R1.fastq.gz").resolve())
    else:
        r1 = _abs(r1)

    if r2:
        r2 = _abs(r2)
    else:
        # Default possible R2 path; may not exist if single-end
        default_r2 = DATA_RAW / f"{sample_id}_R2.fastq.gz"
        r2 = str(default_r2.resolve()) if default_r2.exists() else None

    return r1, r2

def has_reads(sample_id: str) -> bool:
    """
    Convenience: check whether expected read files exist for this sample.
    - ONT: read_path exists and non-empty
    - Illumina: R1 exists (R2 optional)
    """
    row = _SAMPLE_ROWS.get(sample_id)
    if not row:
        return False
    platform = (row.get("platform") or "").lower()
    try:
        if platform == "ont":
            p = Path(raw_read_path(sample_id))
            return p.exists() and p.stat().st_size > 0
        elif platform == "illumina":
            r1, r2 = illumina_read_paths(sample_id)
            ok1 = r1 and Path(r1).exists() and Path(r1).stat().st_size > 0
            if not ok1:
                return False
            if r2:
                return Path(r2).exists() and Path(r2).stat().st_size > 0
            return True
    except Exception:
        return False
    return False