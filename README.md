# ONT Bacterial Genome Assembly (Research Demo) — reproducible pipeline with GLP/GMP‑inspired documentation

## Overview
- Oral Treponema WGS (ONT MinION + Illumina HiSeq): legacy records (2015–2020), a verified 2019 run manifest, SOPs, and an updated Snakemake workflow for new projects.
- Public data linked via NCBI (PRJNA284866). Includes mock manifests for demo/testing. No patient‑identifiable data.

## Purpose
- Reproducible de novo assembly pipeline for bacterial genomes using Oxford Nanopore reads, with QC, polishing, mapping‑based evaluation, and annotation.
- For research and training only; not for diagnostic use.

## Wet‑lab → Dry‑lab flow
- `data/manifests/run_YYYYMMDD.tsv` → parsed to auto‑generate `config/samples.tsv` (see `scripts/manifest_to_samples.py`).
- `data/links/` stores lookups to NCBI accessions; scripts can fetch public metadata/FASTQs for approved accessions.

## Features
- Snakemake pipeline with conda‑locked envs (optional containers).
- Assemblers: Flye or Canu.
- Polishing: Medaka and/or Nanopolish.
- Read mapping: minimap2 (ONT) and BWA‑MEM (Illumina).
- QC: QUAST; optional CheckM.
- Annotation: Prokka.
- Documentation pack: SOP, QC acceptance criteria, deviation/OOS template, validation plan.
- CI: dry‑run on tiny test data.

## Quickstart
```bash
mamba env create -f workflow/envs/base.yaml
conda activate np-asm
python scripts/manifest_to_samples.py  # builds config/samples.tsv from data/manifests/
snakemake --use-conda --cores 8
```

## Inputs/outputs
- Inputs: ONT reads (`*.fastq.gz`); optional Illumina; optional reference.
- Outputs: `assembled.fasta`, `polished.fasta`, mapping BAMs, QC metrics, annotations, summary report.

## Data availability
- Protocols, manifests, and links to public archives only (PRJNA284866; SUB5380773).
- Verified mapping provided for run 2019‑04‑01: `data/manifests/run_20190401.tsv`.
- Raw reads/assemblies are not redistributed here unless public at NCBI.

## Compliance
- Research demo with good documentation and traceability. For regulated use, operate within an accredited QMS and validate per ISO 13485/15189 (or local equivalents).

## Contributions and issues
- PRs and issues welcome. Please avoid adding any PHI or non‑public sample mappings.