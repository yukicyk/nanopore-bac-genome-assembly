# ONT sequencing run manifest: README and guidance

## Purpose
- Define the minimum and recommended metadata to record for each Oxford Nanopore Technologies (ONT) sequencing run.
- Enable reproducible analyses, robust QC, troubleshooting, and audit readiness.
- Support integration with LIMS and compliance frameworks (GDPR, UK DPA, GLP, ISO 9001, ISO 15189).

## How to use this manifest
- Fill one row per sequencing run in manifests/run_manifest_template.tsv. For multiplexed runs, record run-level details here and link per-sample details using sample_id and barcode_id in a separate per-sample sheet.
- Use ISO 8601 timestamps (YYYY-MM-DD or YYYY-MM-DDThh:mmZ).
- Use controlled vocabularies where noted to avoid ambiguity.
- Do not include personal data. Use a pseudonymous linked_clinical_record_id and store PHI/PII separately with restricted access.

## Field-by-field guidance

### Run metadata
- run_id (Required): Unique ID for the run. Example: RUN2025_08_19.
- run_date (Required): Date the run started (YYYY-MM-DD).
- operator: Staff initials or ID. Avoid full names if policy requires.
- instrument_type (Required): MinION | GridION | PromethION.
- device_id: Hardware identifier shown by MinKNOW (e.g., MIN-12345).
- minknow_version (Required): Exact MinKNOW version (e.g., 24.2.5).
- dorado_or_guppy_version: Basecaller version (e.g., Dorado 0.6.1).
- dorado_or_guppy_model: Model (e.g., dna_r10.4.1_e8.2_260bps_sup).
- basecalling_mode: cfg_live (live) | offline (post-run).
- flowcell_id: Manufacturer ID (e.g., FAF12345).
- flowcell_chemistry (Required): R9.4.1 | R10.4.1 etc.
- flowcell_ID: Internal inventory/asset ID (if different).
- kit_code (Required): Library kit code (e.g., SQK-LSK114).
- barcoding_kit: e.g., EXP-NBD114 or SQK-RBK114 if multiplexing.

### Sample and biology
- sample_id (Required): For singleplex, the sample run on this flow cell. For multiplexed runs, this may be the pool name; use per-sample sheet for details.
- organism: NCBI taxon name.
- strain_or_isolate: Lab strain or isolate code.
- source_type (Required): lab_culture | environmental | clinical | synthetic_control.
- source_detail: Free text (e.g., colony on LB plate; soil; wastewater).
- isolate_origin: environmental | clinical.
- culture_medium: e.g., LB, TSB, BHI; include supplier if helpful.
- culture_conditions: Temperature, shaking, time (e.g., 37C, 200 rpm, overnight).
- purity_check: yes | no.
- purity_method: e.g., 16S PCR + Sanger, selective plating.

### Ethics and identifiers
- linked_clinical_record_id: Pseudonymous ID linking to a secure system. No PHI/PII in this file.
- biosample_accession: Public archive BioSample (e.g., SAMN…).
- bioproject_accession: Public project (e.g., PRJNA…).
- sra_run_accessions: SRR IDs post-submission (comma-separated).

### Wet lab and input DNA
- extraction_method (Required): Kit/protocol and version (e.g., Monarch HMW DNA Extraction Kit for Tissue).
- cleanup_method: e.g., AMPure XP beads; ratio if used.
- dna_concentration_ng_per_uL (Required): Qubit dsDNA HS preferred.
- dna_total_ng_loaded (Required): Total input mass.
- volume_loaded_uL (Required): Volume loaded to flow cell.
- a260_280, a260_230: From NanoDrop; contamination indicators.
- fragment_size_N50_kb: Estimated N50 (kb) from sizing instrument.
- sizing_method: TapeStation | Fragment Analyzer | Femto Pulse | PFGE.

### Library and barcodes
- library_protocol_notes: Deviations from kit protocol.
- barcoded: yes | no.
- barcode_id: If barcoded=yes, index used (e.g., NB01, RB01).
- pool_included: yes | no; if yes, link to pool/sample sheet.

### Run performance
- pore_occupancy_initial_pct: Channel occupancy ~10–15 min into run; >70% ideal.
- yield_1h_Mb: Yield in first hour (Mb).
- target_runtime_h: Planned runtime (hours).
- run_end_time: Actual end time (ISO 8601).
- notes: Free-text observations.

### Data locations and integrity
- raw_data_path (Required): Path to raw signal (POD5/FAST5) and MinKNOW logs.
- fastq_output_path: Basecalled FASTQ location.
- demux_output_path: Demultiplexed FASTQ location.
- backup_paths: Off-machine copies (NAS/object store).
- checksum_manifest_path: MD5/SHA256 list for integrity verification.
- submission_date: Date submitted to archives.
- platform (Required): ont.
- read_path: If this manifest drives pipelines, the singleplex FASTQ; for multiplex, leave blank here and use per-sample sheet.
- reference_path: Reference FASTA for reference-guided workflows.

## Controlled vocabularies and formatting
- instrument_type: MinION | GridION | PromethION
- platform: ont
- source_type: lab_culture | environmental | clinical | synthetic_control
- isolate_origin: environmental | clinical
- barcoded: yes | no
- basecalling_mode: cfg_live | offline
- Dates/times: YYYY-MM-DD; or YYYY-MM-DDThh:mmZ
- Use dot as decimal separator; keep units out of values (units documented here).

## Minimal required fields (suggested)
- run_id, run_date, instrument_type, flowcell_chemistry, kit_code, platform
- dna_concentration_ng_per_uL, dna_total_ng_loaded, volume_loaded_uL
- barcoded, basecalling_mode, minknow_version, dorado_or_guppy_version, dorado_or_guppy_model
- raw_data_path, fastq_output_path, backup_paths
- pore_occupancy_initial_pct (if available)

## QC checkpoints aligned to CDC/APHL Bioinformatics QC guidance
- Pre-assembly QC: Record NanoQC/NanoFilt settings and summaries (for ONT).
- Basecalling: Record version, model, pass rate (mean Q and pass thresholds).
- Run metrics: Yield by hour, read length N50, mean Q, pore occupancy.
- Assembly QC: Record assembler, version, parameters, and QUAST metrics (Number of Contigs, Total Length, Largest Contig, GC%, N50/N75; NG50/NG75 and Reference GC% for reference-based workflows).

## Why detailed records matter
- Reproducibility: Captures variables that influence yield, read length, and quality (flow cell lot, kit, model, MinKNOW/basecaller versions).
- Troubleshooting: Enables rapid root-cause analysis (e.g., low occupancy vs extraction quality vs wrong basecalling model).
- Continuous improvement: Supports benchmarking across runs/instruments/operators and retrospective QC.
- Data governance and compliance: Demonstrates process control for GLP, ISO 9001, ISO 15189 and supports audit trails.
- Legal/privacy compliance: GDPR and UK DPA require data minimization and secure processing. Use pseudonymous IDs; keep PHI/PII linkages in restricted systems with access logs and defined retention.

## Compliance and best practice notes
- GDPR and UK DPA:
  - Avoid PHI/PII in the manifest; use pseudonymous IDs only.
  - Keep the mapping key in a secure, access-controlled system.
  - Define retention periods, access control, and auditing.
- GLP and ALCOA(+):
  - Records must be attributable, legible, contemporaneous, original, and accurate. Document deviations.
- ISO 9001:
  - Control this document within your QMS. Version, review, approve, and archive.
- ISO 15189 (clinical):
  - Validate workflows; maintain traceability from specimen to result; ensure staff competency and instrument maintenance records are linked.
- LIMS integration:
  - Keep column names stable; use controlled vocabularies.
  - Use run_id as the primary key; link to per-sample and QC tables.
  - Automate ingestion from MinKNOW/Dorado logs to reduce manual entry.

## Data protection and retention
- Keep manifests in Git; restrict access as appropriate.
- Exclude raw data from Git via .gitignore; store only paths here.
- Maintain checksums for all data; verify on backup and restore tests.

## Example row
- See docs/template/run_manifest_template.tsv for an example. Keep flowcell_chemistry (e.g., R10.4.1) distinct from kit_code (e.g., SQK-LSK114) and from flowcell_id (e.g., FAF12345).

## Common pitfalls
- Mixing flow cell chemistry with IDs or kit codes.
- Omitting basecaller model/version (hurts reproducibility).
- Forgetting barcodes when multiplexing (breaks demultiplex provenance).
- Including personal data in this file (privacy violation).

## References
- CDC/APHL NGS Quality Initiative: https://www.cdc.gov/labquality/qms-tools-and-resources.html
- QUAST manual: https://quast.sourceforge.net/docs/manual.html
- ONT application notes and best practices.
- ALCOA/ALCOA+ data integrity principles.

## Version control
- Store this file at docs/run_manifest_README.md.
- Update the manifest template version in its header if columns change.
- Track changes via pull requests and reviews.