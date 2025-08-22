# Standard Operating Procedure (SOP) for Oxford Nanopore Bacterial Whole-Genome Sequencing (WGS)

**Version**: 1.1
**Effective date**: 2025-08-22
**Author**: Dr. Yuki Chan / Lab
**Approved by**: PI / QA
**Applies to**: Bacterial isolates (pure culture)
**Scope**: End-to-end workflow from culture to sequencing and data processing for ONT instruments, resulting in high-quality assemblies and associated reports.

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
- Record the basecaller version and model used in the run manifest.

### 8.2 Pipeline Setup and Configuration

The pipeline uses two main types of configuration:

1.  **Run Manifests (Schema A+)**:
    - These are your primary experimental records. Before running the pipeline, ensure you have created or updated a manifest file in `data/manifests/` for your run.
    - This file contains detailed metadata about the run and samples. For guidance, see **[run_manifest_README.md](run_manifest_README.md)**.

2.  **Pipeline Configuration (`config/config.yaml`)**:
    - This file controls the *parameters* and *behavior* of the pipeline (e.g., thread counts, tool choices, filtering settings).
    - It does **not** define which samples to run. The pipeline automatically discovers all samples from the manifests.

### 8.3 Running the Pipeline

The workflow is executed using a single `snakemake` command.

1.  **Step 1: Convert Manifests to a Sample Sheet**
    - The pipeline will automatically perform this step. It reads all manifests in `data/manifests/` and generates the primary pipeline input file: `config/samples.tsv` (Schema B). This is handled by the `build_samples_from_manifests` rule.

2.  **Step 2: (Optional) Fetch Public Data**
    - If any sample in `config/samples.tsv` is missing a local read path but has a `biosample_accession`, the `resolve_samples` rule will attempt to download the data from NCBI SRA.
    - This generates the final, authoritative sample sheet: `config/samples.resolved.tsv`.

3.  **Step 3: Execute the Full Pipeline**
    - From the root directory of the repository, run Snakemake. This will execute the entire workflow for all samples defined in your manifests.
    - **Command**:
      ```bash
      # Run the entire pipeline for all samples using 8 cores
      snakemake --cores 8 --use-conda --reason
      ```

4.  **Step 4: Running on a Specific Sample or Target**
    - You can also run the pipeline for a single sample or up to a specific step by specifying the target output file.
    - **Example**: To generate the final polished assembly for only `SMP001`:
      ```bash
      snakemake --cores 8 --use-conda results/polish/SMP001/final_assembly.fasta
      ```

### 8.4 Pipeline Stages and Key Tools

- **Read QC**: **NanoPlot** is run on all ONT reads.
- **Assembly**: **Flye** is the default assembler. This can be changed in `config.yaml`.
- **Polishing**: A multi-step polishing process is applied:
  - **Racon**: One round of short-read correction polishing.
  - **Medaka**: One round of long-read polishing using a neural network model.
- **Evaluation**: The final assembly is evaluated using:
  - **QUAST**: To compare against a reference genome and assess assembly quality metrics (N50, number of contigs, etc.).
  - **Minimap2/Samtools**: To map reads back to the assembly and calculate mean coverage depth.
- **Annotation**: The final polished assembly is annotated using **Prokka**.

### 8.5 Deliverables

After a successful run for a sample (e.g., `SMP001`), the key outputs will be located in the `results/` directory:

- **Final Polished Assembly**: `results/polish/SMP001/final_assembly.fasta`
- **Assembly Evaluation**: `results/evaluation/SMP001/quast/report.html`
- **Coverage Report**: `results/evaluation/SMP001/depth.txt`
- **Annotation**: `results/annotation/SMP001/prokka/SMP001.gff`
- **Initial Read QC**: `results/qc/SMP001/nanoplot/NanoPlot-report.html`

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