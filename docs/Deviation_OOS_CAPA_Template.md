# Deviation, Out-of-Specification (OOS), and CAPA Report

This document provides a template for detailing the investigation and resolution of a deviation or an out-of-specification/out-of-trend result, and outlines the corrective and preventive actions taken.

> **Disclaimer:** The content filled into this template is a fictional example provided for illustrative purposes only. All personnel named (e.g., 'Alex Smith', 'Ben Carter') are hypothetical, with the exception of Dr. Yuki Chan, who is the author of this workflow. This document and the associated workflow are not currently in use in any operational laboratory.

---

### Part 1: Report Identification

| Report ID | Date Opened | Originating SOP/Document | Project Name |
| :--- | :--- | :--- | :--- |
| `CAPA-2025-001` | `2025-09-15` | `SOP_ONT_bacterial_WGS.md` | `QC_Reference_Strain_Validation` |

---

### Part 2: Affected Personnel & Assets

| Sample(s) Affected | Run ID(s) | Operator(s) Involved | Report Author | QA/Reviewer |
| :--- | :--- | :--- | :--- | :--- |
| `Ecoli_Ref_01` | `RUN-20250914-A` | `Alex Smith (Lab), Ben Carter (BioFX)` | `Ben Carter` | `Dr. Yuki Chan` |

---

## Section 1: Description of Deviation / OOS Event

#### 1.1. Detailed Description
*Provide a clear, factual, and concise account of the event. What happened?*

> **Example:** The final genome assembly for the reference strain `Ecoli_Ref_01` resulted in 3 contigs instead of the expected single, complete chromosome. This strain is a well-characterized control with a known single circular chromosome, and this result does not meet the acceptance criteria defined in `QC_Acceptance_Criteria.md`. The analysis was performed as part of the routine validation run `RUN-20250914-A`.

#### 1.2. Point of Detection
*At which specific step of the SOP or analysis was the issue identified? (e.g., DNA Quantification, Post-Run QC, Assembly Evaluation with QUAST, etc.)*

> **Example:** The deviation was identified during the **Assembly Evaluation** step (SOP Section 8.4). The QUAST report, which compares the assembly to the known reference sequence for `Ecoli_Ref_01`, flagged the incorrect number of contigs.

#### 1.3. Expected vs. Actual Result
*Quantify the deviation. Fill in all relevant metrics.*

| Metric / Parameter | Specification / Expected Value | Actual Value Observed | OOS or OOT? |
| :--- | :--- | :--- | :--- |
| *e.g., QUAST # contigs* | *1* | *3* | *OOS* |
| *e.g., Assembly Circularity* | *circular* | *2 linear, 1 circular* | *OOS* |
| *e.g., QUAST N50* | *> 4.5 Mbp* | *4.6 Mbp* | *Within Spec* |
| *e.g., Pore Occupancy %* | *> 70%* | *85%* | *Within Spec* |

---

## Section 2: Immediate Actions & Containment

*Describe the actions taken immediately upon discovery to secure affected samples, data, and prevent further impact.*

- [x] Supervisor / PI / QA Lead was notified. (Date: `2025-09-15`)
- [x] Affected samples/data were quarantined or clearly marked to prevent unintended use.
- [ ] Run was paused or stopped. *(N/A, run was already complete)*
- [ ] Immediate re-measurement was performed (if applicable). *(N/A, this is a pipeline result)*

**Notes on Immediate Actions:**
> **Example:** Dr. Chan was notified via email on 2025-09-15. The results directory `results/Ecoli_Ref_01` was immediately renamed to `results/Ecoli_Ref_01_QUARANTINE_CAPA-2025-001` to prevent it from being included in the final MultiQC report or being delivered. A quick review confirmed that other samples in the same run, which were expected to have plasmids, assembled correctly. The issue appears isolated to the plasmid-free reference strain.

---

## Section 3: Root Cause Investigation (RCI)

#### 3.1. Data and Log Review
*List all documents, logs, and data files reviewed during the investigation.*
- **MinKNOW Logs:** `RUN-20250914-A/minknow_run_logs.txt` (Confirmed nominal run performance)
- **Run Manifest:** `data/manifests/run_manifest_20250914.tsv` (Confirmed DNA quality metrics were met)
- **Snakemake Logs:** `results/Ecoli_Ref_01/logs/assembly/flye.log` (Key finding here)
- **Tool-Specific Logs:** `flye.log` showed the command included the `--plasmids` flag.
- **Instrument Calibration/Maintenance Records:** Checked, all up to date.
- **Reagent/Kit Lot Numbers & Expiry Dates:** Checked, all valid.

#### 3.2. Investigation Method
*Summarize the method used to determine the root cause (e.g., 5 Whys, Fishbone Diagram).*

**Example: 5 Whys Analysis**
1. **Why did the assembly result in 3 contigs?**
   > The assembler, Flye, incorrectly separated the chromosome into one large and two smaller pieces.
2. **Why did Flye separate the chromosome?**
   > The Snakemake log for the job shows that Flye was executed with the `--plasmids` flag. This mode is specifically designed to identify and disentangle potential plasmids from a main chromosome, and it can be overly aggressive on genomes without plasmids.
3. **Why was the `--plasmids` flag used for a reference strain known to have no plasmids?**
   > The pipeline's `Snakefile` was recently updated to apply this flag globally to all ONT assemblies to improve detection in clinical isolates. The rule does not currently differentiate between sample types.
4. **Why did the pipeline update apply this setting globally without exception?**
   > The goal of the update was to standardize the workflow. The potential impact on plasmid-free reference genomes was not considered during the implementation of this change.
5. **Why was this impact not caught during the validation of the pipeline update?**
   > The validation plan for the update only included testing with known plasmid-bearing strains. There was no "negative control" test case using a well-characterized, plasmid-free genome. **(This is the root cause).**

**Example: Fishbone (Ishikawa) Diagram Summary**
- **Manpower/People:** N/A - The operator and bioinformatician correctly followed the existing SOP.
- **Method/Process:** The core issue resides here.
    - The Snakemake pipeline logic was not flexible enough to handle different sample types (plasmid-bearing vs. plasmid-free).
    - The validation protocol for pipeline changes (`Validation_and_Verification_Plan.md`) was insufficient, as it lacked a requirement for negative control testing.
- **Machine/Instrument:** N/A - Sequencer and compute server performed as expected.
- **Material/Reagents:** N/A - DNA quality was confirmed to be high and within all specifications.
- **Measurement:** N/A - QUAST and other QC tools worked correctly and successfully identified the deviation.
- **Environment:** N/A.

[Example Fishbone (Ishikawa) Diagram created in Canva](./FishboneDiagram.png)

#### 3.3. Root Cause Statement
*Based on the investigation, state the single, most fundamental reason for the deviation. This should not be a restatement of the problem. A good root cause statement often points to a process or system failure.*

> **Example:** The root cause was an **inadequate validation protocol for pipeline software changes**, which failed to require testing against a diverse set of use-cases (e.g., plasmid-free genomes). This process gap allowed a global change to the assembly parameters (`--plasmids` flag) to be implemented, leading to the incorrect fragmentation of the reference strain's chromosome.

---

## Section 4: Corrective and Preventive Actions (CAPA)

#### 4.1. Corrective Actions
*Actions taken to resolve the immediate issue for the affected items.*

| Action Description | Assigned To | Due Date | Date Completed |
| :--- | :--- | :--- | :--- |
| Re-run assembly for `Ecoli_Ref_01` with the `--plasmids` flag removed. | `Ben Carter` | `2025-09-16` | `2025-09-16` |
| Archive the quarantined, incorrect assembly data with clear documentation. | `Ben Carter` | `2025-09-16` | `2025-09-16` |

#### 4.2. Preventive Actions
*Actions taken to eliminate the root cause and prevent the issue from recurring in the future.*

| Action Description | Assigned To | Due Date | Date Completed |
| :--- | :--- | :--- | :--- |
| Update `Snakefile` to apply `--plasmids` flag conditionally based on a new column in the sample sheet (e.g., `expect_plasmids: true/false`). | `Ben Carter` | `2025-10-01` | `YYYY-MM-DD` |
| Update `SOP_ONT_bacterial_WGS.md` (Sec 8.2) and `run_manifest_template.tsv` to include the new `expect_plasmids` field and guidance. | `Dr. Yuki Chan` | `2025-10-15` | `YYYY-MM-DD` |
| Update `Validation_and_Verification_Plan.md` to require that all future pipeline changes be tested against a standard set of control samples, including at least one plasmid-positive and one plasmid-negative genome. | `Dr. Yuki Chan` | `2025-10-15` | `YYYY-MM-DD` |
| Conduct a brief training session for all lab and bioinformatics staff on the updated SOP and the reason for the change. | `Ben Carter` | `2025-10-20` | `YYYY-MM-DD` |

---

## Section 5: Verification of Effectiveness

#### 5.1. Verification Plan
*How will the effectiveness of the implemented CAPA be measured? Be specific.*

> **Example:** "The next five (5) bacterial WGS runs that include a plasmid-free reference strain will be monitored. The `expect_plasmids` column will be set to `false` for these samples. The Snakemake logs must confirm that the `--plasmids` flag was NOT used for these specific samples. The resulting QUAST report for each must show a single contig and meet all other assembly QC criteria as defined in `QC_Acceptance_Criteria.md`. This will be reviewed by the QA Lead."

#### 5.2. Verification Results and Conclusion
*Record the outcome of the verification plan. Was the CAPA effective?*

> **Example:** Verification was performed on runs `RUN-20251025-A` through `RUN-20251115-C`. In all seven instances where a plasmid-free reference was used with `expect_plasmids: false`, the logs confirmed the correct command was used, and the assemblies were successful (single, circular contig). The conditional logic is working as intended. The CAPA is verified as effective and this report can be closed.

---

## Section 6: Approval and Closure

*Signatures below indicate that the investigation is complete, all actions have been implemented and verified, and the report is closed.*

| Role | Name | Signature | Date |
| :--- | :--- | :--- | :--- |
| Report Author | Ben Carter | *(digital signature)* | `2025-11-20` |
| QA Lead / Reviewer | Dr. Yuki Chan | *(digital signature)* | `2025-11-21` |
| Principal Investigator | | *(digital signature)* | |

---

### Appendix: Definitions and References

- **OOS (Out of Specification):** A test result that falls outside the pre-defined acceptance criteria or limits established for a product or process.
- **OOT (Out of Trend):** A test result that, while within specification, shows a significant deviation from historical data or expected patterns.
- **CAPA (Corrective and Preventive Action):** A systematic, two-part process to (1) identify and resolve the immediate problem (**Corrective Action**) and (2) identify the root cause to prevent the problem from happening again (**Preventive Action**).
- **5 Whys:** An iterative interrogative technique used to explore the cause-and-effect relationships underlying a particular problem. The primary goal is to determine the *root cause* of a defect or problem by repeating the question "Why?".
- **Fishbone (Ishikawa) Diagram:** A cause-and-effect diagram that helps to visually organize potential causes of a problem into logical categories (e.g., Manpower, Method, Machine, Material) to identify root causes.
- **Reference:** For further reading on quality management principles, see the U.S. FDA's guidance on Quality Systems and CAPA: [FDA CFR Title 21 Part 820.100].