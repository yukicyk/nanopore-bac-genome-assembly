#!/usr/bin/env python3
import csv, sys, json
from pathlib import Path

def main(tsv_path):
    samples = []
    p = Path(tsv_path)
    if not p.exists():
        print(json.dumps({'error': f'not found: {p}'}))
        return
    with p.open('r', newline='') as fh:
        reader = csv.DictReader(fh, delimiter='\t')
        required = {'sample_id','platform','read_path'}
        headers = [h.strip() for h in (reader.fieldnames or [])]
        missing = required - set(headers)
        if missing:
            print(json.dumps({'error': f'missing columns: {sorted(missing)}'}))
            return
        for row in reader:
            sample = (row.get('sample_id') or '').strip()
            plat = (row.get('platform') or '').strip().lower()
            rpath = (row.get('read_path') or '').strip()
            if not sample:
                continue
            samples.append({'sample_id': sample, 'platform': plat, 'read_path': rpath})
    print(json.dumps({'samples': samples}))

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(json.dumps({'error': 'usage: read_samples_tsv.py <samples.tsv>'}))
    else:
        main(sys.argv[1])
