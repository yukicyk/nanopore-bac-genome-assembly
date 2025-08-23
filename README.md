# High-Quality Bacterial Genome Assembly Pipeline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Snakemake](https://img.shields.io/badge/snakemake-≥7.0-brightgreen.svg)](https://snakemake.github.io)


A robust, reproducible, and standards-aware Snakemake pipeline for assembling high-quality bacterial genomes from Oxford Nanopore (ONT) data.

This workflow is designed with best practices for clinical and research environments in mind, emphasizing traceability, quality control, and comprehensive documentation, inspired by GLP and ISO standards.

---

## Features

- **Reproducible**: Uses Conda environments to ensure all tools are version-locked.
- **Scalable**: Easily runs on one sample or hundreds by simply adding a manifest file.
- **Modular**: The workflow is broken into logical, self-contained rule files.
- **Quality-Focused**: Integrates multiple polishing and evaluation steps (Racon, Medaka, QUAST).
- **Automated Reporting**: Generates a final summary report with key QC metrics for all samples.
- **Comprehensive Documentation**: Includes a full SOP, validation plans, and QC acceptance criteria.

## Workflow Overview

The pipeline automates the following steps, from raw reads to an annotated assembly and final report:

graph TD
    A[Input: Run Manifests] --> B{Read QC <br/>(NanoPlot)}
    B --> C{Assembly <br/>(Flye)}
    C --> D{Polishing <br/>(Racon + Medaka)}
    D --> E[Final Polished Assembly]
    E --> F{Evaluation <br/>(QUAST + Depth)}
    E --> G{Annotation <br/>(Prokka)}
    F & G --> H[Output: Summary Report]

## Quick Start Guide
1. Prerequisites
Ensure you have Conda (or preferably Mamba) installed on your system.

2. Installation
Clone the repository and create the main Snakemake environment.

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
cd YOUR_REPOSITORY

# Create the Conda environment for Snakemake
# This environment is only for running the Snakemake orchestrator
mamba env create -f pipeline/envs/snakemake.yaml
conda activate snakemake_env
```
(Note: We need to create a snakemake.yaml environment file. See the box below.)

3. Configuration
 1. Add Run Manifests: Place your experimental metadata files (in .tsv format) into the data/manifests/ directory. You can use data/manifests/run_manifest_template.tsv as a starting point. The pipeline will automatically find and process all samples listed in these files.

 2. Customize Parameters (Optional): Edit config/config.yaml to adjust tool parameters, thread counts, or change the default assembler/polisher.

4. Execution
Run the pipeline. Snakemake will automatically handle the creation of all other required software environments.

```bash
# Perform a dry-run to see what tasks will be executed
snakemake -n --use-conda

# Execute the full pipeline on all available cores
snakemake --cores all --use-conda --reason
```
Upon completion, the final results will be in the results/ directory, and a full summary can be found in reports/assembly_summary_report.md.

## Directory Structure

```
.
├── config/         # Pipeline configuration and generated sample sheets
├── data/           # Input manifests describing runs and samples
├── docs/           # Project documentation (SOP, QC criteria, etc.)
├── pipeline/       # The Snakemake workflow (Snakefile, rules, envs)
├── results/        # All output files, organized by sample and step
└── scripts/        # Helper scripts used by the pipeline.
├── config/         # Pipeline configuration and generated sample sheets
├── data/           # Input manifests describing runs and samples
├── docs/           # Project documentation (SOP, QC criteria, etc.)
├── pipeline/       # The Snakemake workflow (Snakefile, rules, envs)
├── results/        # All output files, organized by sample and step
└── scripts/        # Helper scripts used by the pipeline

```

## Detailed Documentation

For a complete understanding of the workflow, quality control procedures, and data governance, please refer to the documents in the docs/ directory:

- **SOP_ONT_bacterial_WGS.md:** The primary Standard Operating Procedure for the entire workflow.
- **run_manifest_README.md:** Detailed guidance on how to fill out the run manifest.
- **QC_Acceptance_Criteria.md:** Specific QC thresholds for accepting or rejecting a result.
- **Validation_and_Verification_Plan.md:** The plan for validating the pipeline's performance.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

