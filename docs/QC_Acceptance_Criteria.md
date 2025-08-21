## docs/QC_Acceptance_Criteria.md

- DNA QC: concentration ≥ X ng/µl; A260/280 1.8–2.0; HMW DNA confirmation (gel/TapeStation) if available.
- Basecalling QC: mean Q score ≥ 9–10 (adjust for chemistry); read N50 ≥ threshold for organism (~10–20 kb typical if HMW).
- Assembly QC (draft): single contig preferred for circular chromosomes, else minimal contigs; total length within ±10% expected; NGA50 ≥ threshold; QUAST misassemblies = 0 major.
- Polishing QC: mapping depth ≥ 30× (preferred ≥ 60×); mismatch/indel rates below thresholds (report both).
- Contamination: taxonomic assignment dominated by target organism (>95%) or justified.
- Documentation: all versions, seeds, and parameters captured in run log.
