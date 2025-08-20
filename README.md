# ONT Bacterial Genome Assembly (Research Demo) — reproducible pipeline with GLP/GMP‑inspired documentation

## Overview
- Oral Treponema WGS (ONT MinION + Illumina HiSeq): legacy records (2015–2020), a verified 2019 run manifest, SOPs, and an updated Snakemake workflow for new projects.
- Public data linked via NCBI (PRJNA284866). Includes mock manifests for demo/testing. No patient‑identifiable data.

## Purpose
- Reproducible de novo assembly pipeline for bacterial genomes using Oxford Nanopore reads, with QC, polishing, mapping‑based evaluation, and annotation.
- For research and training only; not for diagnostic use.

## Wet‑lab → Dry‑lab flow
- Record each run in a single manifest: data/manifests/run_YYYYMMDD.tsv (Schema A+: Run Manifest & Metadata).
- Generate the workflow table from the manifest(s): scripts/manifest_to_samples.py → config/samples.tsv (Schema B: Workflow Samples).
- Optional: in cases we have NCBI accession IDs to the Biosamples/ SRA, but not the raw data, put the accessions in the config/samples.tsv, the workflow can fetch FASTQs from public when biosample_accession or srrs (SRA accession) is present and read_path is empty.

## Features
- Snakemake pipeline with conda‑locked envs (optional containers).
- Assemblers: Flye or Canu.
- Polishing: Medaka and/or Nanopolish.
- Read mapping: minimap2 (ONT) and BWA‑MEM (Illumina).
- QC: QUAST; optional CheckM.
- Annotation: Prokka.
- Documentation pack: SOP, QC acceptance criteria, deviation/OOS template, validation plan.
- CI: dry‑run on tiny test data.

## Where the workflow starts

- Entry point: workflow/Snakefile (Snakemake loads this file).
- Practical SOP position: after basecalling/demultiplexing (SOP §8.2). 

## Metadata and Schemas

This repository distinguishes between two related tables:

- Schema A+ — Run Manifest & Metadata (wet‑lab centric)
- Schema B — Workflow Samples (pipeline centric)

Why two? We keep a comprehensive, auditable record of metadeata per sequencing run; while this workflow only needs a few columns to analyze sequencing reads. We maintain one detailed metadata file per experiment (Schema A+) and derive a slim table for the pipeline (Schema B).

### Schema A+ — Run Manifest & Metadata (wet‑lab)

- File: one TSV per sequencing run (e.g., `data/manifests/run_YYYYMMDD.tsv`).
- Audience: wet‑lab, QA/GLP, future audits and automation.
- Content: both run‑level and sample‑level fields in a single table (run fields repeated per row).
- Required column now:
  - `sample_id`
- Optional but recommended:
  - `platform` (ont|illumina)
  - `barcode_id` (if multiplexing)
  - `biosample_accession` (leave blank initially; add after NCBI submission)
  - `fastq_path` or `fastq_guess` (if you already have per‑sample FASTQ)
- Additional fields are necessary for bookkeeping and traceability (instrument, flow cell IDs, kits, DNA QC, sample details, QC metrics, etc.).
- Template: see `docs/templates/run_manifest_template.tsv`.

Important: `biosample_accession` is often not available before de novo assembly. It is optional in Schema A+. Add later when data is submitted to NCBI (Bioproject/BioSample/SRA).

### Schema B — Workflow Samples (pipeline centric)

- File:
  - Input: `config/samples.tsv`
  - After fetch/resolve: `config/samples.resolved.tsv`
- Audience: the Snakemake workflow.
- Columns (this exact order is written by our helper):
  - `sample_id` (required)
  - `platform` (required: ont|illumina)
  - `read_path` (required column; value may be empty if using fetch)
  - `biosample_accession` (optional; required only if you want the workflow to fetch from NCBI)
  - `barcode` (optional)
- Behavior:
  - If `read_path` points to an existing `.fastq(.gz)`, the workflow uses it.
  - If `read_path` is empty and `biosample_accession` is present, the `resolve_samples` rule can fetch reads from NCBI SRA into `data/raw/{sample_id}.fastq.gz` and write `config/samples.resolved.tsv`.
  - If both `read_path` and `biosample_accession` are empty, fetching is skipped for that sample.

### From Schema A+ to Schema B

Use the helper to convert your manifest(s) into a workflow‑ready table:

```bash
python scripts/manifest_to_samples.py \
  --manifests_glob "data/manifests/*.tsv" \
  --out config/samples.tsv \
  --default-platform ont
```
### Manifest validation

- The validator runs by default to validate your Schema A+ manifests against the template and recommended fields:
          workflow/envs/validate-manifest.yaml
- To Run on its own:
        snakemake --use-conda -p validate_manifests

- Fail the workflow if critical fields are missing:
VALIDATE_STRICT=true snakemake --use-conda -p validate_manifests
- To skip validation entirely (not recommended), run specific downstream targets instead of all, e.g.:
        snakemake --use-conda -p results/qc/summary.tsv
- Reports:
   - reports/manifest_validation.txt
   - reports/manifest_validation.json

- Automatic read_path inference
   - When your manifest includes demux_output_path and barcode_id, manifest_to_samples.py will try to infer per-sample FASTQ paths using common Dorado/Guppy layouts:
     - demux/barcodeNN/*.fastq.gz
     - demux/barcodeNN/fastq_pass/*.fastq.gz
     - demux/barcodeNN.fastq.gz
     - demux/barcodeNN_*.fastq.gz
     - demux/barcodeNN/reads.fastq.gz
   - If an explicit fastq_path/read_path is present, it takes precedence.

## Tips:
- If your manifest includes fastq_path or fastq_guess, those will populate read_path automatically.
- You can always edit config/samples.tsv to point read_path to your local FASTQ files under data/raw/.

## Typical workflows
- Local FASTQs (new analyses)

   * Maintain a detailed run manifest (Schema A+) during the experiment.
   * Convert to Schema B and ensure read_path points to your local .fastq.gz.
   * Run the pipeline. No NCBI fetch happens.
   * NCBI/public re‑analysis (no local FASTQs)

- Convert to Schema B. Leave read_path empty.
   * Add biosample_accession (when available).
   * Run snakemake with the resolve_samples rule enabled; it fetches and fills read_path.

- Rationale for optional BioSample accessions
   - In real lab timelines, NCBI accessions are obtained after assembly/analysis or at publication time. Therefore, biosample_accession is optional in both A+ and B. It is only required if you want the workflow to download public reads automatically.
   You can run the entire workflow with local data and never use NCBI fetching.

## Outputs
- Outputs: `assembled.fasta`, `polished.fasta`, mapping BAMs, QC metrics, annotations, summary report.

## Compliance and good recording (GLP/GDP hints)
- Record who/when/where, instrument identifiers, SOP version, consumable lot numbers.
- Track raw data paths and checksums; confirm backups.
- Capture key QC: initial pore occupancy, early yield, read N50, mean Q/pass rate.
- For clinical sources, link to pseudonymized patient IDs stored separately to meet UK GDPR/DPA.
- Research demo with good documentation and traceability. For regulated use, operate within an accredited QMS and validate per ISO 13485/15189 (or local equivalents).

## Quickstart
```bash
# 0) Clone repo and ensure mamba/conda is available

# 1) Build config/samples.tsv (Schema B) from your run manifest(s) (Schema A+)
python scripts/manifest_to_samples.py \
  --manifests_glob "data/manifests/*.tsv" \
  --out config/samples.tsv \
  --default-platform ont

#    Optionally, you may create config/samples.tsv manually (tab-delimited; exact headers):
#    sample_id  platform  read_path  biosample_accession  barcode

# 2) If you have local FASTQs, set read_path for each sample to your .fastq(.gz).
#    If you do not have local FASTQs but have BioSample accessions, leave read_path empty.

# 3) Test the fetch/resolve step (only affects samples with empty read_path)
snakemake --use-conda --cores 4 -R resolve_samples -p

# 4) Run QC or full pipeline targets
snakemake --use-conda --cores 8 -p

# Notes:
# - resolve_samples writes an updated table to config/samples.tsv (or the configured fetch.out)
#   and only fetches from NCBI if read_path is empty and biosample_accession is set.
# - Fetched reads are stored under data/raw/{sample_id}.fastq.gz.
# - The fetch environment is defined in workflow/envs/fetch.yaml (includes SRA Toolkit).
```

## Data availability
- Protocols, manifests, and links to public archives only (PRJNA284866; SUB5380773).
- Verified mapping provided for run 2019‑04‑01: `data/manifests/run_20190401.tsv`.
- Raw reads/assemblies are not redistributed here, they are public at NCBI.

## Contributions and issues
- PRs and issues welcome. Please avoid adding any PHI or non‑public sample mappings.