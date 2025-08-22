# ==============================
# File: pipeline/rules/io.smk
# ==============================

from pathlib import Path

# Expect these globals from main Snakefile:
# - REPO, CFG_DIR, SCRIPTS_DIR
# - SAMPLES_TSV_OUT (absolute Path)
print(f"[io.smk] REPO={REPO} CFG_DIR={CFG_DIR} SCRIPTS_DIR={SCRIPTS_DIR}")

def _read_tsv_rows(tsv_path):
    import csv
    rows = []
    p = Path(tsv_path)
    if not p.exists():
        return rows
    with p.open("r", newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        for row in reader:
            rows.append({(k or "").strip(): (v or "").strip() for k, v in row.items()})
    return rows

def read_samples(tsv_path=None):
    """
    Return a list of sample IDs from the provided TSV (defaults to config/samples.resolved.tsv).
    A sample is considered present if it has sample_id and platform.
    """
    tsv = str(tsv_path or SAMPLES_TSV_OUT)
    rows = _read_tsv_rows(tsv)
    samples = []
    for r in rows:
        sid = (r.get("sample_id") or "").strip()
        plat = (r.get("platform") or "").strip().lower()
        if not sid or not plat:
            continue
        samples.append(sid)
    # Stable unique order
    seen = set()
    out = []
    for s in samples:
        if s in seen:
            continue
        seen.add(s)
        out.append(s)
    return out

def read_samples_records(tsv_path=None):
    """
    Return dict: {sample_id: record} for quick lookup.
    """
    tsv = str(tsv_path or SAMPLES_TSV_OUT)
    rows = _read_tsv_rows(tsv)
    out = {}
    for r in rows:
        sid = (r.get("sample_id") or "").strip()
        if not sid:
            continue
        out[sid] = r
    return out

def raw_read_path(sample_id, tsv_path=None):
    """
    Return the primary FASTQ path for a sample.
    - ONT: read_path
    - Illumina: prefer read_path_r1 (for per-sample QC), else read_path (if mistakenly provided), else empty.
    """
    records = read_samples_records(tsv_path)
    rec = records.get(sample_id, {})
    plat = (rec.get("platform") or "").strip().lower()
    if plat == "illumina":
        r1 = (rec.get("read_path_r1") or "").strip()
        if r1:
            return r1
        # fallback if someone provided read_path
        rp = (rec.get("read_path") or "").strip()
        if rp:
            return rp
        return ""
    else:
        # default to ONT behavior
        rp = (rec.get("read_path") or "").strip()
        return rp

def illumina_pair_paths(sample_id, tsv_path=None):
    """
    Return tuple (r1, r2) for Illumina sample; empty strings if unavailable.
    """
    records = read_samples_records(tsv_path)
    rec = records.get(sample_id, {})
    r1 = (rec.get("read_path_r1") or "").strip()
    r2 = (rec.get("read_path_r2") or "").strip()
    return r1, r2