# Deviation, Out-of-Specification (OOS), and CAPA Report

This document details the investigation and resolution of a deviation or an out-of-specification/out-of-trend result, and outlines the corrective and preventive actions taken.

---

### Part 1: Report Identification

| Report ID | Date Opened | Originating SOP/Document | Project Name |
| :--- | :--- | :--- | :--- |
| `CAPA-YYYY-NNN` | `YYYY-MM-DD` | `SOP_ONT_bacterial_WGS.md` | |

---

### Part 2: Affected Personnel & Assets

| Sample(s) Affected | Run ID(s) | Operator(s) Involved | Report Author | QA/Reviewer |
| :--- | :--- | :--- | :--- | :--- |
| | | | | |

---

## Section 1: Description of Deviation / OOS Event

#### 1.1. Detailed Description
*Provide a clear, factual, and concise account of the event. What happened?*

>

#### 1.2. Point of Detection
*At which specific step of the SOP or analysis was the issue identified? (e.g., DNA Quantification, Post-Run QC, Assembly Evaluation with QUAST, etc.)*

>

#### 1.3. Expected vs. Actual Result
*Quantify the deviation. Fill in all relevant metrics.*

| Metric / Parameter | Specification / Expected Value | Actual Value Observed | OOS or OOT? |
| :--- | :--- | :--- | :--- |
| *e.g., DNA A260/280 Ratio* | *1.8 – 2.0* | *1.65* | *OOS* |
| *e.g., Pore Occupancy %* | *> 70%* | *45%* | *OOS* |
| *e.g., QUAST # contigs* | *1* | *5* | *OOT* |
| | | | |

---

## Section 2: Immediate Actions & Containment

*Describe the actions taken immediately upon discovery to secure affected samples, data, and prevent further impact.*

- [ ] Supervisor / PI / QA Lead was notified. (Date: `YYYY-MM-DD`)
- [ ] Affected samples/data were quarantined or clearly marked to prevent unintended use.
- [ ] Run was paused or stopped.
- [ ] Immediate re-measurement was performed (if applicable).

**Notes on Immediate Actions:**
>

---

## Section 3: Root Cause Investigation (RCI)

#### 3.1. Data and Log Review
*List all documents, logs, and data files reviewed during the investigation.*
- **MinKNOW Logs:** (Path/ID)
- **Run Manifest:** (`run_manifest_XYZ.tsv`)
- **Snakemake Logs:** (`logs/...`)
- **Tool-Specific Logs:** (e.g., `flye.log`, `medaka.log`)
- **Instrument Calibration/Maintenance Records:**
- **Reagent/Kit Lot Numbers & Expiry Dates:**

#### 3.2. Investigation Method
*Summarize the method used to determine the root cause (e.g., 5 Whys, Fishbone Diagram).*

**Example: 5 Whys Analysis**
1. **Why?**
2. **Why?**
3. **Why?**
4. **Why?**
5. **Why?**

**Example: Fishbone (Ishikawa) Diagram Summary**
- **Manpower/People:**
- **Method/Process:**
- **Machine/Instrument:**
- **Material/Reagents:**
- **Measurement:**
- **Environment:**

#### 3.3. Root Cause Statement
*Based on the investigation, state the single, most fundamental reason for the deviation. This should not be a restatement of the problem.*

>

---

## Section 4: Corrective and Preventive Actions (CAPA)

#### 4.1. Corrective Actions
*Actions taken to resolve the immediate issue for the affected items.*

| Action Description | Assigned To | Due Date | Date Completed |
| :--- | :--- | :--- | :--- |
| *e.g., Re-extract DNA from backup isolate* | *Operator A* | `YYYY-MM-DD` | `YYYY-MM-DD` |
| *e.g., Re-run basecalling with correct model* | *BioFX Lead* | `YYYY-MM-DD` | `YYYY-MM-DD` |

#### 4.2. Preventive Actions
*Actions taken to eliminate the root cause and prevent the issue from recurring in the future.*

| Action Description | Assigned To | Due Date | Date Completed |
| :--- | :--- | :--- | :--- |
| *e.g., Update SOP to include check for model* | *QA Lead* | `YYYY-MM-DD` | `YYYY-MM-DD` |
| *e.g., Conduct refresher training for all staff* | *Lab Manager* | `YYYY-MM-DD` | `YYYY-MM-DD` |
| *e.g., Add QC checkpoint to LIMS* | *IT/LIMS Admin*| `YYYY-MM-DD` | `YYYY-MM-DD` |

---

## Section 5: Verification of Effectiveness

#### 5.1. Verification Plan
*How will the effectiveness of the implemented CAPA be measured? Be specific.*

> **Example:** "The next five (5) bacterial WGS runs will be monitored. The QUAST report for each must show a single contig and meet all other assembly QC criteria as defined in `QC_Acceptance_Criteria.md`. This will be reviewed by the QA Lead."

#### 5.2. Verification Results and Conclusion
*Record the outcome of the verification plan. Was the CAPA effective?*

>

---

## Section 6: Approval and Closure

*Signatures below indicate that the investigation is complete, all actions have been implemented and verified, and the report is closed.*

| Role | Name | Signature | Date |
| :--- | :--- | :--- | :--- |
| Report Author | | | |
| QA Lead / Reviewer | | | |
| Principal Investigator | | | |

---

### Appendix: Definitions

- **OOS (Out of Specification):** A test result that falls outside the pre-defined acceptance criteria or limits established for a product or process.
- **OOT (Out of Trend):** A test result that, while within specification, shows a significant deviation from historical data or expected patterns.
- **CAPA (Corrective and Preventive Action):** A systematic, two-part process to (1) identify and resolve the immediate problem (**Corrective Action**) and (2) identify the root cause to prevent the problem from happening again (**Preventive Action**).