print(f"[io.smk] REPO={REPO} CFG_DIR={CFG_DIR} SCRIPTS_DIR={SCRIPTS_DIR}")
# ==============================
# File: pipeline/rules/io.smk
# ==============================
from pathlib import Path
import os
import json
import subprocess
from typing import Dict, List


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
    Read the pipeline samples table (TSV; tab-delimited) via scripts/read_samples_tsv.py.
    Returns a list of sample_ids. If the TSV is missing at parse time, return [] to stay lazy.
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
        raise RuntimeError(
            f"Failed to parse JSON from {READ_SAMPLES}: {e}\nSTDOUT:\n{stdout}"
        )
    samples = [row.get("sample_id") for row in data.get("samples", []) if row.get("sample_id")]
    return samples

def raw_read_path(sample_id: str) -> str:
    """
    Resolve the read_path for a sample from the resolved TSV. This function is called at job expansion time.
    The actual TSV parsing is delegated to the helper script to keep schema logic in one place.
    """
    # The Snakefile constructs SAMPLES_TSV_OUT and passes it indirectly by calling this function
    # with current working directory at the repo root. The helper script returns all rows; find the one we need.
    # Reuse read_samples_tsv.py but we need the full row data; call it once and cache.
    # We implement a tiny cache keyed by the TSV path.
    return _resolve_read_path_from_cache(sample_id)

# Lightweight cache and resolver
_LAST_TSV = None
_ROW_CACHE = None

def _load_rows(tsv_path: Path):
    global _LAST_TSV, _ROW_CACHE
    if _ROW_CACHE is not None and _LAST_TSV == tsv_path:
        return _ROW_CACHE
    if not tsv_path.exists():
        _LAST_TSV = tsv_path
        _ROW_CACHE = []
        return _ROW_CACHE
    proc = subprocess.run(
        [str(READ_SAMPLES), str(tsv_path)],
        check=True,
        capture_output=True,
        text=True,
    )
    data = json.loads(proc.stdout or "{}")
    _LAST_TSV = tsv_path
    _ROW_CACHE = data.get("samples", [])
    return _ROW_CACHE

def _resolve_read_path_from_cache(sample_id: str) -> str:
    # Determine the resolved TSV path the main Snakefile uses; infer as config/fetch.out default
    # We don’t have direct access here; rely on runtime calling context to pass the resolved TSV to rules.
    # As a fallback, check the two common locations in the repo:
    candidates = [
        CFG_DIR / "samples.resolved.tsv",
        CFG_DIR / "samples.tsv",
    ]
    for tsv in candidates:
        rows = _load_rows(tsv)
        if rows:
            for row in rows:
                if (row.get("sample_id") or "") == sample_id:
                    rp = (row.get("read_path") or "").strip()
                    return _abs(rp)
    # Nothing found; return empty to cause a clear error when a rule tries to use it
    return ""