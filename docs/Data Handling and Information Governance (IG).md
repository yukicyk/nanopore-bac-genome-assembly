# Information Governance and Data Handling Policy

## 1. Document Purpose
This document outlines the Information Governance (IG) policy for this repository and its associated data analysis workflows. Its purpose is to ensure that all data is handled securely, ethically, and in a manner that guarantees integrity and reproducibility, in alignment with established best practices and legal frameworks.

---

## 2. Scope and Data Classification

### 2.1. In-Scope Data
This policy and repository exclusively cover the handling of **publicly available or simulated demonstration data**.
- **Primary Data:** Raw instrument signals (e.g., `.pod5`, `.fast5`), base-called reads (e.g., `FASTQ`), and derived data (e.g., assemblies, variant calls).
- **Metadata:** Non-identifiable sample information, run parameters, and quality control metrics.
- **Pseudonymous Identifiers:** A single, project-specific pseudonymous key (e.g., `linked_clinical_record_id`) is permitted **only** as a reference link.

### 2.2. Strictly Out-of-Scope Data
This repository **must not**, under any circumstances, be used to store or transmit any of the following:
- **Personal Identifiable Information (PII):** Data that can be used to directly identify an individual (e.g., name, address, date of birth, contact information).
- **Protected Health Information (PHI):** Any health or medical information linked to an identifiable individual.
- **Linkage Keys:** Any file or data that directly maps the pseudonymous identifier back to PII/PHI.

---

## 3. Core Governance Principles
Our data handling strategy is founded on the following internationally recognised principles:

- **Lawfulness, Fairness, and Transparency:** All data sources will be clearly documented. We will be transparent about the processing steps applied to the data through version-controlled code and comprehensive documentation.
- **Data Minimisation (UK GDPR / DPA 2018):** We are committed to using the minimum amount of data necessary to achieve the project's scientific goals. No data containing direct personal identifiers will be downloaded or stored.
- **Pseudonymisation:** Where data originates from a clinical context (even if anonymised for public release), we will rely on a single pseudonymous key (`linked_clinical_record_id`). The key that links this ID back to the original patient data **must** be stored in a separate, secure, access-controlled system (e.g., a hospital LIMS) and is never to be included in this repository.
- **Integrity and Availability (ALCOA+):** Data integrity is paramount. We will maintain data quality and assurance through checksums, automated testing, and secure backup procedures. Data must be attributable, legible, contemporaneous, original, and accurate.
- **Confidentiality and Access Control:** Access to the repository and its infrastructure will be managed according to the principle of least privilege.
- **Accountability:** All significant actions related to code and configuration are tracked. All deviations from standard procedure must be formally documented.

---

## 4. Practical Implementation and Procedures

### 4.1. Data Storage: Paths, Not Payloads
- **Git Repository:** The Git repository is for **code and configuration only**. This includes Snakefiles, scripts, environment definitions, and manifests.
- **`.gitignore`:** All raw and processed data file types (e.g., `*.pod5`, `*.fastq.gz`, `*.bam`, `*.fasta`) **must** be listed in the `.gitignore` file to prevent accidental commits.
- **Manifest Files:** Data files will be tracked using manifest files (e.g., `config/samples.tsv`). These manifests contain file paths, metadata, and checksums, but not the data itself.

### 4.2. Access Control and Code Review
- **Branch Protection:** The `main` branch is protected. Direct pushes are disabled.
- **Pull Requests (PRs):** All changes to code, configuration, or manifests must be submitted via a Pull Request.
- **Required Reviews:** PRs require at least one review and approval from a designated code owner or maintainer before merging. This ensures changes are vetted for correctness and compliance with this policy.

### 4.3. Data Integrity and Verification
- **Checksums:** All critical input data files (raw signals, FASTQ) should have a corresponding SHA256 checksum recorded in a manifest or a dedicated `checksums.sha256` file.
- **Automated Verification:** Workflows should, where possible, include steps to verify file checksums before processing to detect data corruption.
- **Backup Strategy:** All primary raw data and essential metadata (manifests, logs) must be backed up to a separate, off-host location (e.g., institutional secure storage, cloud object storage). Backups should be performed on a defined schedule.

### 4.4. Retention and Deletion
- **Data Retention Policy:** The laboratory or project group must define and document a data retention period appropriate for the data type and project requirements (e.g., "5 years post-publication").
- **Deletion Procedure:** A formal procedure for the secure deletion of data at the end of its retention period must be documented. This includes removing the data from primary storage, backups, and updating all relevant manifests.

### 4.5. Audit Trail and Deviation Management
- **Git History:** The Git commit history serves as the primary audit trail for all changes to the workflow's code and configuration. Commit messages should be clear and descriptive.
- **Release Notes:** Tagged releases should be accompanied by release notes summarising key changes, new features, and bug fixes.
- **Deviation Reporting:** Any deviation from this policy or an established SOP (Standard Operating Procedure) must be recorded and investigated using the formal template provided in `docs/Deviation_OOS_CAPA_Template.md`.

---

## 5. Governing Standards and References
This policy is guided by principles derived from the following standards and regulations:
- **UK General Data Protection Regulation (UK GDPR)**
- **Data Protection Act 2018 (DPA 2018)**
- **ALCOA+ Principles** for data integrity (Attributable, Legible, Contemporaneous, Original, Accurate, Complete, Consistent, Enduring, and Available).
- **ISO 9001 / ISO 15189:** Principles of quality management systems, process control, and traceability.

---

## 6. Document Control
| Version | Date       | Author(s) | Summary of Changes |
| :---    | :---       | :---      | :---               |
| 1.0     | 2025-08-21 | Dr. Y Chan| Initial draft      |
|         |            |           |                    |