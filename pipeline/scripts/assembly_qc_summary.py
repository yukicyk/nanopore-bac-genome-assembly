#!/usr/bin/env python3
"""
Aggregates key QC metrics from multiple samples into a single Markdown report.

This script is designed to be called from a Snakemake rule. It expects the following
named lists in `snakemake.input`:
- quast_reports: A list of paths to QUAST 'report.tsv' files.
- depth_reports: A list of paths to 'depth.txt' files.
- gff_files: A list of paths to GFF files for annotation summary.
"""

import pandas as pd
import re
from pathlib import Path
from datetime import datetime

def parse_quast_report(path: Path) -> dict:
    """Parses a QUAST report.tsv file for key metrics."""
    if not path.exists():
        return {}
    
    # Read the two-column TSV into a dictionary
    report_df = pd.read_csv(path, sep='\t', header=None, index_col=0, names=['Metric', 'Value'])
    metrics = report_df.to_dict()['Value']
    
    return {
        'Contigs': metrics.get('# contigs', 'N/A'),
        'Total Length': metrics.get('Total length', 'N/A'),
        'Largest Contig': metrics.get('Largest contig', 'N/A'),
        'N50': metrics.get('N50', 'N/A'),
        'GC (%)': metrics.get('GC (%)', 'N/A'),
    }

def parse_depth_file(path: Path) -> str:
    """Parses the simple 'Mean depth: X' file."""
    if not path.exists():
        return "N/A"
    
    content = path.read_text()
    match = re.search(r'Mean depth:\s*([\d\.]+)', content)
    return f"{float(match.group(1)):.1f}x" if match else "N/A"

def count_cds_in_gff(path: Path) -> int:
    """Counts the number of CDS features in a GFF file."""
    if not path.exists():
        return 0
    
    count = 0
    with path.open('r') as f:
        for line in f:
            if line.startswith('#'):
                continue
            fields = line.split('\t')
            if len(fields) > 2 and fields[2] == 'CDS':
                count += 1
    return count

def get_sample_id_from_path(path: Path) -> str:
    """Extracts the sample ID from a file path like 'results/.../{sample}/...'."""
    # This regex looks for the pattern /<directory>/<sample_id>/
    match = re.search(r"results/[^/]+/([^/]+)/", str(path))
    if match:
        return match.group(1)
    raise ValueError(f"Could not extract sample ID from path: {path}")

def main():
    """Main script execution."""
    summary_data = []

    # Use the list of QUAST reports as the primary loop iterator
    for quast_path_str in snakemake.input.quast_reports:
        quast_path = Path(quast_path_str)
        sample_id = get_sample_id_from_path(quast_path)
        
        # Find corresponding files for the same sample_id
        depth_path = Path(f"results/evaluation/{sample_id}/depth.txt")
        gff_path = Path(f"results/annotation/{sample_id}/prokka/{sample_id}.gff") # Assumes Prokka
        
        # Parse all data for the sample
        quast_metrics = parse_quast_report(quast_path)
        mean_depth = parse_depth_file(depth_path)
        cds_count = count_cds_in_gff(gff_path)
        
        sample_summary = {
            'Sample ID': sample_id,
            'Contigs': quast_metrics.get('Contigs'),
            'Total Length': quast_metrics.get('Total Length'),
            'N50': quast_metrics.get('N50'),
            'GC (%)': quast_metrics.get('GC (%)'),
            'Mean Depth': mean_depth,
            'CDS Count': cds_count,
        }
        summary_data.append(sample_summary)

    # Create a DataFrame for easy formatting
    summary_df = pd.DataFrame(summary_data)

    # Generate the Markdown output
    report_content = f"""
# Assembly QC Summary Report

**Report generated on**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

This report summarizes the final assembly quality metrics for all processed samples.

{summary_df.to_markdown(index=False)}

---
**Total samples processed**: {len(summary_data)}
"""

    # Write the report to the output file defined in the Snakemake rule
    with open(snakemake.output[0], "w") as f:
        f.write(report_content.strip())

if __name__ == "__main__":
    # This block is for Snakemake to execute the script
    main()