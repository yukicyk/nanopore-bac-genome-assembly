# Standard Operating Procedure (SOP) for Oxford Nanopore Bacterial Whole-Genome Sequencing (WGS)

- **Version**: 1.3
- **Effective date**: 2025-08-30
- **Author**: Dr. Yuki Chan
- **Approved by**: PI / QA
- **Applies to**: Bacterial isolates (pure culture)
- **Scope**: End-to-end workflow from culture to sequencing and data processing for ONT instruments, resulting in high-quality assemblies and associated reports.

## 1. Purpose

To describe standardized procedures for extracting high-molecular-weight (HMW) DNA from bacterial isolates, preparing Oxford Nanopore sequencing libraries, running ONT flow cells, and performing a reproducible bioinformatics analysis to generate high-quality genome assemblies.

## 2. Responsibilities

- **Operator**: Performs wet-lab procedures, instrument setup, and initial QC.
- **Bioinformatics lead**: Manages and executes the bioinformatics pipeline, reviews QC, and archives data.
- **QA/PI**: Reviews and approves results, deviations, and SOP updates.

## 3. Safety

- Follow institutional biosafety procedures. For detailed hazards, see the project's **[Risk_Assessment_and_Biosafety.md](Risk_Assessment_and_Biosafety.md)**.
- Wear appropriate PPE: lab coat, gloves, eye protection.
- Handle all chemicals according to their Safety Data Sheet (SDS).

## 4. Definitions and Abbreviations

- **ONT**: Oxford Nanopore Technologies
- **WGS**: Whole-genome sequencing
- **HMW**: High-molecular-weight
- **SOP**: Standard Operating Procedure
- **OOS/OOT**: Out of Specification / Out of Trend.
- **CAPA**: Corrective and Preventive Action.

## 5. Materials and Equipment

- **Instruments**: ONT MinION/GridION/PromethION; compatible computer with GPU and ≥2 TB storage.
- **Flow cells**: R9.4.1 or R10.4.1 (e.g., FLO-MIN114).
- **Library kits**: Ligation (e.g., SQK-LSK114) or Rapid Barcoding (e.g., SQK-RBK114).
- **DNA extraction**: HMW DNA kit (e.g., Qiagen Genomic-tip 100/G).
- **Quantification**: Qubit dsDNA HS kit.
- **Software**: MinKNOW, Dorado/Guppy, and the `nanopore-bac-genome-assembly` Snakemake pipeline.

## 6. Sample Requirements

- **Input**: Pure, single-colony bacterial culture.
- **Purity**: Confirmed by streaking. For detailed purity methods, see the run manifest template.
- **DNA Input (Ligation)**:
  - Concentration: ≥20–50 ng/µL
  - Total mass: 400–1000 ng
  - A260/280: 1.8–2.0; A260/230: ≥2.0
  - Fragment size: Majority >20 kb.
- **Acceptance Criteria**: For specific thresholds, refer to **[QC_Acceptance_Criteria.md](QC_Acceptance_Criteria.md)**.

## 7. Procedure

(Sections 7.1 - 7.7 remain largely the same, covering Culture, DNA Extraction, QC, Library Prep, and Sequencing Run)

- **Documentation**: For every run, create a new run manifest file based on **[run_manifest_template.tsv](../data/manifests/run_manifest_template.tsv)**. Record all wet-lab and instrument parameters as specified in **[run_manifest_README.md](run_manifest_README.md)**.

## 8. Bioinformatics Workflow

This section details the use of the `nanopore-bac-genome-assembly` Snakemake pipeline.

### 8.1 Basecalling and Demultiplexing

- After the run, perform basecalling and demultiplexing using the latest recommended version of **Dorado** or **Guppy**.
- **Example (Dorado)**:
  ```bash
  # Basecall raw POD5 files
  dorado basecaller sup <model> <input_pod5_dir> > basecalls.bam

  # Demultiplex using the BAM output
  dorado demux --kit-name <KIT_NAME> --output-dir demux/ basecalls.bam
  ```
- Record the basecaller version and model, and the path to the final FASTQ files  in your run manifest.

### 8.2 Pipeline Setup and Configuration

The pipeline requires a single, definitive sample sheet named `config/samples.resolved.tsv`. This file can be generated in two primary ways:

1.  **Pathway A (For Lab-Generated Data)**:
    - First, record all experimental metadata in a `run_manifest.tsv` file located in `data/manifests/`. Use the provided template and see `run_manifest_README.md` for detailed guidance.
    - Next, run the helper script to convert your manifest into the primary sample sheet:

    ```bash
     python pipeline/scripts/manifest_to_samples.py
    ```
    - This creates `config/samples.tsv`.

2.  **Pathway B (For Public Data or Manual Entry)**:
    - Manually create or edit the `config/samples.tsv` file.
    - Instead of providing local file paths for `ont_reads`, `illumina_r1`, etc., you can provide public accession codes in the `biosample` or `srrs` columns.

3. **Final Unification Step**:
    - Run the final helper script that takes config/samples.tsv as input, downloads any public data if necessary, and generates the pipeline's true input file:
    ```bash
    python pipeline/scripts/fetch_or_prompt.py
    ```
    This script creates `config/samples.resolved.tsv`, where all read paths are guaranteed to be local and valid. The Snakemake pipeline reads only from this file.
    - This script creates `config/samples.resolved.tsv`, where all read paths are guaranteed to be local and valid. The Snakemake pipeline reads only from this file.


### 8.3 Executing the Pipeline

Once `config/samples.resolved.tsv` is present, you can execute the entire workflow.

1.  **Activate the Environment**:
      ```bash
      conda activate bac-wgs-env
      ```
2.  **Execute the Full Pipeline**:
    - From the root directory of the repository, run Snakemake. This will execute the entire workflow for all samples defined in config/samples.resolved.tsv.
    - Command:
        ```bash
        # Run the entire pipeline for all samples using all available cores
        snakemake --cores all --use-conda --reason --snakefile pipeline/Snakefile
        ```

3.  **Running on a Specific Target**:
    - To generate a specific output file for a single sample (e.g., SMP001), provide that file as the target.
    - Example:
      ```bash
      snakemake --cores 8 --use-conda results/SMP001/annotation/bakta/SMP001.gbff --snakefile pipeline/Snakefile
      ```

### 8.4 Pipeline Stages and Key Tools

- **Read QC**: **NanoPlot** is run on all ONT reads. **FastQC** is run on all Illumina paired-end reads.
- **Assembly**: 
   - for samples with ONT reads (hybrid or ONT-only):**Flye** is used for long-read assembly.
   - For samples with only Illumina reads: **SPAdes** is used for short-read assembly.
- **Polishing**: A multi-step polishing process is applied depending on the input data:
   - **ONT-only data**: The Flye assembly is polished once with Medaka.
   - **Hybrid data (ONT + Illumina)**: The Flye assembly is first polished with Medaka (long-read), and the result is then polished with Pilon (short-read) for final error correction.
   - **Illumina-only data**: No polishing is performed on the SPAdes assembly.
- **Evaluation**: The final assembly is evaluated using:
  - **QUAST**: To compare against a reference genome and assess assembly quality metrics (N50, number of contigs, etc.).
- **Plasmid Identification**: The final polished assembly is analyzed with MOB-suite to identify and characterize plasmid-derived contigs. This tool predicts plasmid mobility and identifies known replicon families. For ONT-based assemblies, `Flye` is run with the `--plasmids flag` to aid in separating chromosomal and plasmid sequences.
- **Annotation**: The final polished assembly is annotated using **Bakta** (default) or **Prokka**. The choice is configured in `config/config.yaml`.

### 8.5 Deliverables

After a successful run, the key outputs for each sample are in the `results/` directory. The exact path to the final assembly depends on the input data type.

#### For examples:

**For a hybrid sample (ONT + Illumina) named** `SMP001`:

- Final Polished Assembly: `results/SMP001/polish/pilon/assembly.fasta`
- Annotation: `results/SMP001/annotation/bakta/SMP001.gbff` (or `.../prokka/...gff`)

**For an ONT-only sample named** `SMP002`:

- Final Polished Assembly: `results/SMP002/polish/medaka/consensus.fasta`
- Annotation: `results/SMP002/annotation/bakta/SMP002.gbff` (or `.../prokka/...gff`)

**For an Illumina-only sample named** `SMP003`:

- Final Assembly: `results/SMP003/assembly/spades/scaffolds.fasta`
- Annotation: `results/SMP003/annotation/bakta/SMP003.gbff` (or `.../prokka/...gff`)

**For all samples:**

- **Assembly Evaluation**: `results/{sample}/evaluation/quast/report.html`
- **Aggregate QC Report**: `results/multiqc_report.html`
- **Plasmid Analysis**: `results/{sample}/plasmid_id/mob_suite/`
   - `mob_recon_report.txt`: A summary of predicted plasmids, their quality, and mobility.
   - `contig_report.txt`: A report classifying each input contig as chromosomal or plasmid-derived.

## 9. Quality Control and Acceptance Criteria

- All pipeline steps are subject to QC checks. Specific, measurable thresholds for DNA quality, run performance, and assembly metrics are defined in **[QC_Acceptance_Criteria.md](QC_Acceptance_Criteria.md)**.
- Any deviation from this SOP or failure to meet acceptance criteria must be documented. Use the **[Deviation_OOS_CAPA_Template.md](Deviation_OOS_CAPA_Template.md)** to record the issue, investigation, and corrective actions.

## 10. Documentation and Data Retention

- All run metadata must be captured in the run manifest.
- Raw data and pipeline results must be backed up according to lab policy.
- For details on data handling, refer to the project's **[Data_Handling_and_Information_Governance.md](Data_Handling_and_Information_Governance.md)**.
- Publicly available data associated with this project is described in **[data_availability.md](data_availability.md)**.

## 11. Validation

The pipeline's performance and functionality are verified and validated according to the plan outlined in **[Validation_and_Verification_Plan.md](Validation_and_Verification_Plan.md)**.