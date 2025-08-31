# Standard Operating Procedure (SOP) for Oxford Nanopore Bacterial Whole-Genome Sequencing (WGS)

- **Version**: 1.3a
- **Effective date**: 2025-08-31
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
- **Flow cells**: R9.4.1 or R10.4.1 or latest version (e.g., FLO-MIN114).
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

- **Documentation**: For every run, create a new run manifest file based on **[run_manifest_template.tsv](../data/manifests/run_manifest_template.tsv)**. 
- Record all wet-lab and instrument parameters as specified in **[run_manifest_README.md](run_manifest_README.md)**.
- (Not required by the Snakemake workflow, but recommended as general good lab practice) Record all sample details and specifications as suggested in **[docs/template/per-sample_template.tsv]([../docs/template/per-sample_template.tsv)**.

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
    - This script creates `config/samples.resolved.tsv`, where all read paths are guaranteed to be local and valid. The Snakemake pipeline reads only from this file.


### 8.3 Executing the Pipeline

Once `config/samples.resolved.tsv` is present, the workflow can be executed.

1.  **Activate the Conda Environment**:
    ```bash
    conda activate bac-wgs-env
    ```

2.  **Execute the Full Pipeline**:
    - From the repository's root directory, run Snakemake. This executes the entire workflow for all samples defined in `config/samples.resolved.tsv`.
    - It is highly recommended to perform a "dry-run" by adding the `-n` (or `--dry-run`) flag before full execution. A dry-run prints the jobs that will be executed without running them, which is the best way to verify the targets and dependencies.
    - **Commands**:
      ```bash
      # Perform a dry-run to inspect the job plan
      snakemake -n --use-conda --reason --snakefile pipeline/Snakefile

      # Execute the full pipeline using all available cores
      snakemake --cores all --use-conda --reason --snakefile pipeline/Snakefile
      ```

3.  **Running on a Specific Target**:
    - To generate a specific output file for a single sample (e.g., `SMP001`), provide the path to that file as a target on the command line.
    - **Note**: When targeting a file, the workflow automatically runs any prerequisite steps if their outputs are missing. It will use existing intermediate files whenever possible.
    - **Note**: By default, Snakemake will not re-run jobs if the output file already exists. To force a rule to re-run, either delete the output file first or use the `--force` flag.

    #### Targeting Specific Pipeline Stages:
    The following examples demonstrate how to request specific outputs for different sample types:
    - **Hybrid sample (ONT + Illumina):** `SMP001`
    - **ONT-only sample:** `SMP002`
    - **Illumina-only sample:** `SMP003`

    1.  **To Run Only the Read QC Step**:
        - **Target**: The final HTML report from the QC tool.
        - **Example Paths**: `results/SMP002/qc/nanoplot/NanoPlot-report.html` (for ONT) or `results/SMP003/qc/fastqc/SMP003_R1_fastqc.html` (for Illumina).
        - **Command**:
          ```bash
          # Request the NanoPlot report for sample SMP002
          snakemake --cores 8 --use-conda --reason results/SMP002/qc/nanoplot/NanoPlot-report.html --snakefile pipeline/Snakefile
          ```

    2.  **To Run Only the Genome Assembly Step**:
        - **Description**: Generates initial contigs from reads using Flye or SPAdes.
        - **Target**: The primary assembly FASTA file.
        - **Example Paths**: `results/SMP002/assembly/flye/assembly.fasta` (for ONT) or `results/SMP003/assembly/spades/scaffolds.fasta` (for Illumina).
        - **Command**:
          ```bash
          # This command runs read QC (a dependency) and then the Flye assembly for SMP002
          snakemake --cores 16 --use-conda --reason results/SMP002/assembly/flye/assembly.fasta --snakefile pipeline/Snakefile
          ```

    3.  **To Run Up to the Polishing Step**:
        - **Description**: Polishes the raw assembly with Medaka and/or Pilon. Note: Polishing is not applicable to Illumina-only data.
        - **Target**: The final polished FASTA file.
        - **Example Paths**: `results/SMP001/polish/pilon/assembly.fasta` (for hybrid) or `results/SMP002/polish/medaka/consensus.fasta` (for ONT-only).
        - **Command**:
          ```bash
          # This runs all prerequisite steps and finishes with Pilon polishing for SMP001
          snakemake --cores 16 --use-conda --reason results/SMP001/polish/pilon/assembly.fasta --snakefile pipeline/Snakefile
          ```

    4.  **To Run Only the Assembly Evaluation Step**:
        - **Description**: Runs QUAST on a finished assembly to generate quality metrics.
        - **Target**: The main QUAST report file.
        - **Example Path**: `results/SMP001/evaluation/quast/report.html`.
        - **Command**:
          ```bash
          # This generates the required assembly first, then runs QUAST on it
          snakemake --cores 4 --use-conda --reason results/SMP001/evaluation/quast/report.html --snakefile pipeline/Snakefile
          ```

    5.  **To Run Only the Annotation Step**:
        - **Description**: Annotates the final polished assembly using Bakta or Prokka.
        - **Target**: The final annotated GenBank file (`.gbff`).
        - **Example Path (assuming Bakta)**: `results/SMP001/annotation/bakta/SMP001.gbff`.
        - **Command**:
          ```bash
          # This generates the polished assembly and then runs annotation
          snakemake --cores 8 --use-conda --reason results/SMP001/annotation/bakta/SMP001.gbff --snakefile pipeline/Snakefile
          ```

    6.  **To Run Only the Plasmid Identification Step**:
        - **Description**: Runs MOB-suite on the final assembly. Note: This step only runs if enabled in `config/config.yaml`.
        - **Target**: The MOB-suite contig report.
        - **Example Path**: `results/SMP001/plasmid/mob_suite/contig_report.txt`.
        - **Command**:
          ```bash
          # This generates the assembly and then runs MOB-suite
          snakemake --cores 8 --use-conda --reason results/SMP001/plasmid/mob_suite/contig_report.txt --snakefile pipeline/Snakefile
          ```

    7.  **To Generate Only the Final MultiQC Report**:
        - **Description**: Aggregates results from all completed steps into a single report.
        - **Target**: The final HTML report file.
        - **Path**: `results/multiqc_report.html`.
        - **Command**:
          ```bash
          # Use --force to re-generate the report even if it already exists
          snakemake --force --cores 1 --use-conda --reason results/multiqc_report.html --snakefile pipeline/Snakefile
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
- **Evaluation**: The final assembly is evaluated using **QUAST** to assess quality metrics (e.g., N50, number of contigs).
- **Plasmid Identification**: The final assembly is analyzed with **MOB-suite** to identify and characterize plasmid-derived contigs. For ONT-based assemblies, `Flye` is run with the `--plasmids` flag to aid in separating chromosomal and plasmid sequences.
- **Annotation**: The final polished assembly is annotated using **Bakta** (default) or **Prokka**. The tool is configured in `config/config.yaml`.

### 8.5 Deliverables

After a successful run, key outputs for each sample are located in the `results/` directory.

#### Example Output Paths:

**For a hybrid sample (ONT + Illumina) named `SMP001`**:
- **Final Polished Assembly**: `results/SMP001/polish/pilon/assembly.fasta`
- **Annotation**: `results/SMP001/annotation/bakta/SMP001.gbff`

**For an ONT-only sample named `SMP002`**:
- **Final Polished Assembly**: `results/SMP002/polish/medaka/consensus.fasta`
- **Annotation**: `results/SMP002/annotation/bakta/SMP002.gbff`

**For an Illumina-only sample named `SMP003`**:
- **Final Assembly**: `results/SMP003/assembly/spades/scaffolds.fasta`
- **Annotation**: `results/SMP003/annotation/bakta/SMP003.gbff`

**For all samples**:
- **Assembly Evaluation**: `results/{sample}/evaluation/quast/report.html`
- **Aggregate QC Report**: `results/multiqc_report.html`
- **Plasmid Analysis**: `results/{sample}/plasmid_id/mob_suite/`
  - `mob_recon_report.txt`: A summary of predicted plasmids, quality, and mobility.
  - `contig_report.txt`: A classification of each input contig as chromosomal or plasmid-derived.

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