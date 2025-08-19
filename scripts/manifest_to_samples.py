#!/usr/bin/env python3
import argparse
import csv
import glob
import os
import sys
from typing import List, Dict

REQUIRED_COLS = ["sample_id", "barcode_id", "biosample_accession"]

def read_manifest(path: str) -> List[Dict[str, str]]:
    with open(path, "r", newline="", encoding="utf-8") as fh:
        # auto-detect delimiter (tab expected)
        sample = fh.read(4096)
        fh.seek(0)
        sniffer = csv.Sniffer()
        dialect = sniffer.sniff(sample, delimiters="\t,;")
        reader = csv.DictReader(fh, dialect=dialect)
        missing = [c for c in REQUIRED_COLS if c not in (reader.fieldnames or [])]
        if missing:
            raise ValueError(f"{path} missing required columns: {missing}. Found: {reader.fieldnames}")
        rows = [row for row in reader if any((v or "").strip() for v in row.values())]
        return rows

def main():
    ap = argparse.ArgumentParser(description="Compile sample table from manifests.")
    ap.add_argument("--manifests_glob", required=True, help="Glob for manifest TSV files, e.g., 'data/manifests/*.tsv'")
    ap.add_argument("--out", required=True, help="Output path for samples.tsv")
    args = ap.parse_args()

    paths = sorted(glob.glob(args.manifests_glob))
    if not paths:
        print(f"No manifests matched: {args.manifests_glob}", file=sys.stderr)
        return 1

    rows_all: List[Dict[str, str]] = []
    for p in paths:
        try:
            rows = read_manifest(p)
            for r in rows:
                rows_all.append({
                    "sample_id": (r.get("sample_id") or "").strip(),
                    "barcode": (r.get("barcode_id") or "").strip(),
                    "biosample": (r.get("biosample_accession") or "").strip()
                })
        except Exception as e:
            print(f"Error reading {p}: {e}", file=sys.stderr)
            return 1

    # de-duplicate by sample_id while preserving order
    seen = set()
    deduped = []
    for r in rows_all:
        sid = r["sample_id"]
        if not sid:
            continue
        if sid in seen:
            continue
        seen.add(sid)
        deduped.append(r)

    # validate minimal fields
    for r in deduped:
        if not (r["sample_id"] and r["barcode"] and r["biosample"]):
            print(f"Incomplete row (requires sample_id, barcode, biosample): {r}", file=sys.stderr)
            return 1

    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "w", newline="", encoding="utf-8") as outfh:
        writer = csv.DictWriter(outfh, fieldnames=["sample_id", "barcode", "biosample"], delimiter="\t")
        writer.writeheader()
        for r in deduped:
            writer.writerow(r)

    print(f"Wrote {args.out} with {len(deduped)} samples.", file=sys.stderr)
    return 0

if __name__ == "__main__":
    sys.exit(main())