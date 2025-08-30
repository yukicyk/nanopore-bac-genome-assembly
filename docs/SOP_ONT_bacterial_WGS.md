Aquí tienes el contenido completo y definitivo del archivo SOP_ONT_bacterial_WGS.md con la adición de la sección de "Detección de Plásmidos".

He insertado la nueva sección antes de la de "Evaluación" para que el flujo de trabajo siga una secuencia lógica.

Markdown

# Standard Operating Procedure (SOP) for Oxford Nanopore Bacterial Whole-Genome Sequencing (WGS)

- **Version**: 1.2
- **Effective date**: 2025-08-25
- **Author**: Dr. Yuki Chan / Lab
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