# Verification and Validation Plan (excerpt)

Objective: Verify pipeline on a known organism (E. coli K-12 MG1655) and validate performance on representative genomes.

Verification (pipeline function)
- Input: tiny ONT FASTQ test set; reference MG1655.
- Expected: pipeline completes; produces assembly and QC metrics.
- Acceptance: CI completes within 10–15 minutes; QUAST runs; basic metrics present.

Validation (performance)
- Datasets: HMW DNA high-quality ONT runs (n≥3).
- Metrics: completeness, NGA50, total length vs expected, GC%, error rates (Illumina polishing optional), contamination.
- Thresholds: define in docs/QC_Acceptance_Criteria.md; justify based on literature and lab history.