#!/usr/bin/env python3
import csv, sys, json

# New flexible schema: only sample_id and platform are strictly required.
# ont reads can be specified with read_path, and illumina reads with read_path_r1 and read_path_r2.
# biosample and srrs are optional for metadata, but not used in this script. If srrs are provided, they will be used to fetch reads in fetch script. 
REQUIRED = {"sample_id","platform"}

def main(tsv_path):
    samples = []
    with open(tsv_path, 'r', newline='') as fh:
        reader = csv.DictReader(fh, delimiter='\t')
        headers = [h.strip() for h in (reader.fieldnames or [])]
        missing = REQUIRED - set(headers)
        if missing:
            print(json.dumps({'error': f'missing columns: {sorted(missing)}'}))
            sys.exit(0)

        # Optional columns we’ll pass through if present
        has_rpath = "read_path" in headers
        has_r1 = "read_path_r1" in headers
        has_r2 = "read_path_r2" in headers

        for row in reader:
            sample = (row.get('sample_id') or '').strip()
            plat = (row.get('platform') or '').strip().lower()
            if not sample:
                continue

            out = {'sample_id': sample, 'platform': plat}

            # ONT single-end path
            if has_rpath:
                rpath = (row.get('read_path') or '').strip()
                if rpath:
                    out['read_path'] = rpath

            # Illumina paired-end paths
            if has_r1:
                r1 = (row.get('read_path_r1') or '').strip()
                if r1:
                    out['read_path_r1'] = r1
            if has_r2:
                r2 = (row.get('read_path_r2') or '').strip()
                if r2:
                    out['read_path_r2'] = r2

            samples.append(out)

    print(json.dumps({'samples': samples}))

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print(json.dumps({'error': 'usage: read_samples_tsv.py <samples.tsv>'}))
        sys.exit(0)
    main(sys.argv[1])