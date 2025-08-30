# High-Quality Bacterial Genome Assembly Pipeline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Snakemake](https://img.shields.io/badge/snakemake-≥7.0-brightgreen.svg)](https://snakemake.github.io)
[![Snakemake CI](https://github.com/yukicyk/nanopore-bac-genome-assembly/actions/workflows/ci.yml/badge.svg)](https://github.com/yukicyk/nanopore-bac-genome-assembly/actions/workflows/ci.yml)

A robust, reproducible, and standards-aware Snakemake pipeline for assembling high-quality bacterial genomes from Oxford Nanopore (ONT) and (optional) Illumina data.

This workflow is designed with best practices for clinical and research environments in mind, emphasizing traceability, quality control, and comprehensive documentation, inspired by GLP and ISO standards.

---

## Features

- **Reproducible**: Uses Conda environments to ensure all tools are version-locked.
- **Scalable**: Easily runs on one sample or hundreds through a simple, two-step input process.
- **Modular**: The workflow is broken into logical, self-contained rule files.
- **Quality-Focused**: Integrates multiple polishing and evaluation steps (Medaka, Pilon, QUAST).
- **Automated Reporting**: Generates a final MultiQC report with key metrics for all samples.
- **Comprehensive Documentation**: Includes a full SOP, validation plans, and QC acceptance criteria.
- **Plasmid-aware**: Incorporates a specific stage to identify and assemble plasmid sequences.

## Workflow Overview

The pipeline automates all steps from prepared reads to an annotated assembly. The input data flow is designed to be flexible for both wet-lab and dry-lab users.

```mermaid
   flowchart TD
    subgraph "Phrase 1"
        direction LR
        B ~~~ id1{{"`**Phase 1: 
        Input Preparation 
        (Manual or Scripted)**
     `"}}
        A["Input: run_manifest.tsv"] --> |manifest_to_samples.py| B["config/samples.tsv"];
        C["Input: Accession IDs <br> (e.g., SRR...)"] --> |Manual Edit| B;
        B --> |fetch_or_prompt.py| D["config/samples.resolved.tsv <br> **Pipeline's True Input**"];
    end

    subgraph "Phase 2"
        C ~~~ id2{{"`**Phase 2: 
        Automated Pipeline
        (Snakemake)**
        `"}}
        D --> E["Raw Read QC <br> (NanoPlot / FastQC)"];
        E --> F["Genome Assembly <br> (Flye / SPAdes)"];
        F --> G["Assembly Polishing <br> (Medaka / Pilon)"];
        G --> H["Final High-Quality Assembly"];
        H --> H_p["Plasmid Detection"];
        H_p --> I["Evaluation (QUAST)"];
        H_p --> J["Annotation (Bakta or Prokka)"];
        E & I & J & H_p --> K["Final Summary Report <br> (MultiQC)"];
        
    end