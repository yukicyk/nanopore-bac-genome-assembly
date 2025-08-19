
# Title: Standard Operating Procedure (SOP) for Oxford Nanopore Bacterial Whole-Genome Sequencing (WGS)

**Version**: 1.0
**Effective date**: YYYY-MM-DD
**Author**: Your Name / Lab
**Approved by**: PI / QA
**Applies to**: Bacterial isolates (pure culture)
**Scope**: End-to-end workflow from culture to FASTQ/assemblies for ONT instruments (e.g., MinION/GridION/PromethION).

1. Purpose

  To describe standardized procedures for extracting high-molecular-weight (HMW) DNA from bacterial isolates, preparing Oxford Nanopore sequencing libraries, running ONT flow cells, and performing basecalling, QC, and downstream analysis to generate high-quality assemblies and associated reports.

2. Responsibilities

 - Operator: Performs wet-lab procedures, instrument setup, and initial QC.
 - Bioinformatics lead: Runs basecalling and analysis, reviews QC, archives data.
 - QA/PI: Reviews and approves results, deviations, and SOP updates.

3. Safety

- Follow institutional biosafety procedures (BSL-2 for most pathogens).
- Wear PPE: lab coat, gloves, eye protection.
- Handle phenol/ethanol/NaOH/bleach per SDS, in fume hood where applicable.
- Decontaminate work surfaces and dispose of biological waste properly.

4. Definitions and abbreviations

- ONT: Oxford Nanopore Technologies
- WGS: Whole-genome sequencing
- HMW DNA: High-molecular-weight DNA
- QC: Quality control
- Q-score: Phred-equivalent quality score
- R9.4.1/R10.4.1: Common ONT flow cell chemistries
- Kit codes: e.g., SQK-LSK114 (ligation), SQK-RBK114 (rapid barcoding)

5. Materials and equipment
- Instruments: ONT MinION/GridION/PromethION; compatible computer with GPU (optional) and ≥2 TB storage for projects
- Flow cells: R9.4.1 or R10.4.1 (FLO-MIN106D, FLO-MIN114, FLO-PRO114, etc.)
- Library kits: Choose one
   * Ligation: SQK-LSK114 (+ barcoding EXP-NBD114 if multiplexing)
   * Rapid barcoding: SQK-RBK114
- DNA extraction reagents: HMW DNA kit (e.g., Qiagen Genomic-tip 100/G) or phenol-free HMW protocol; RNase A; optional bead cleanup (AMPure XP or ONT Short Fragment Buffer)
- Quantification and sizing: Qubit dsDNA HS kit, Nanodrop (optional), TapeStation/Fragment Analyzer (optional pulsed-field gel)
- Consumables: Low-bind tubes, wide-bore tips, magnetic rack, nuclease-free water
- Software:
  * ONT: MinKNOW, Guppy or Dorado (basecalling), ONT Cloud/Local workflows as needed
  * QC: NanoPlot, pycoQC, FastQC (optional)
  * Assembly: Flye, Raven, Canu (optional), Medaka/PEPPER-Polish, Racon
  * Annotation and typing: Prokka/Bakta, mlst, abricate, AMRFinderPlus
  * Contamination/Completeness: CheckM, BUSCO (bacteria), Kraken2/Bracken
  * Other: Porechop/porechop_abi (adapter trimming if necessary), filtlong (read filtering)

6. Sample requirements

- Input: Pure, single-colony bacterial culture grown on appropriate medium.
- Purity: Confirm by streaking and colony morphology; optional 16S PCR if needed.
- DNA input requirements (typical for ligation kits):
  * Concentration: ≥20–50 ng/µL
  * Total mass per barcode: 400–1000 ng (see kit manual)
  * A260/280: 1.8–2.0; A260/230: ≥2.0
  * Fragment size: Majority >20 kb preferred; avoid shearing.
- Storage: DNA at 4°C short-term (≤72 h) or −20°C/−80°C long-term.

7. Procedure

 7.1 Culture and cell harvest

- Streak isolate, incubate to obtain fresh overnight culture.
- Harvest 1–5 mL cells (species-dependent). Avoid overgrowth to limit DNA degradation.
- Pellet at 5,000–8,000 × g for 5–10 min; remove supernatant.

 7.2 DNA extraction (HMW)

- Use a validated HMW DNA protocol (e.g., Qiagen Genomic-tip) minimizing pipetting shear.
- Include RNase A treatment.
- Perform gentle mixing (invert, flick); avoid vortexing post-lysis.
- Purify DNA; elute in 10 mM Tris-HCl pH 8.5 or nuclease-free water.
- Optional: Additional cleanup using 0.45×–0.8× bead ratio to remove small fragments.

 7.3 DNA QC and normalization

- Quantify with Qubit dsDNA HS (preferred). Record concentration.
- Check purity on Nanodrop; if A260/230 <1.8, perform cleanup.
- Assess fragment size distribution (optional) with TapeStation/FA or PFGE.
- Normalize DNA to kit-specific input: see Section 6.

 7.4 Library preparation

Choose kit; follow the official ONT protocol current to your chemistry.

   A) Ligation kit (SQK-LSK114)

  - DNA repair/end-prep according to kit.
  - Adapter ligation with AMX; incubate as specified.
  - Clean-up with beads; elute in EB.
  - For multiplexing: Perform native barcoding (EXP-NBD114) before adapter ligation.
  - Handle gently; use wide-bore tips.
   B) Rapid barcoding kit (SQK-RBK114)

  - Mix DNA with RB reagent; incubate per protocol.
  - Pool barcoded samples; add sequencing adapters per kit.

7.5 Flow cell QC and priming

- Check flow cell pore count in MinKNOW; accept ≥800 active pores for MinION (lab threshold; adjust for R10).
- Prime flow cell per chemistry instructions (Flush Buffer/Flush Tether).
- Load library at recommended concentration/volume. Record sample sheet.

7.6 Sequencing run

- Configure run in MinKNOW:
  * Flow cell type, kit chemistry, barcodes used.
  * Output: write raw POD5/BLOW5 or FAST5 and enable “output FASTQ” if using live basecalling.
  * Set run time (e.g., 24–72 h) or yield target.
- Optional live basecalling with Dorado/Guppy (SUP/ HAC models per use case).
- Monitor:
  * Pore occupancy (>70% ideal in first hour)
  * Yield and read length N50
  * Quality (mean Q, pass rate)
- If pore occupancy falls quickly, consider nuclease flush and reload if protocol allows.

7.7 Post-run handling

- Stop run; perform final wash/nuclease flush if reusing flow cell (per ONT guidance).
- Back up run data (raw signals + FASTQ + logs) to lab storage.

8. Bioinformatics workflow

8.1 Basecalling and demultiplexing

- Use Dorado (preferred) or Guppy with appropriate model for your chemistry:
   - Dorado example:
     dorado basecaller sup <model> <input_pod5> > out.bam
     dorado demux --kit <RBK/NBD kit> out.bam -o demux/
- Alternatively, run Guppy with the correct config for R9/R10 and kit.
- Record versions and models in metadata.

8.2 Read QC

- NanoPlot on FASTQ (per barcode):
   - NanoPlot --fastq reads.fastq.gz -o nanoplot/
- Optional adapter trimming with porechop_abi if adapters persist.
- Remove very short/low-quality reads if required:
   - filtlong --min_length 1000 --keep_percent 95 input.fastq.gz > filtered.fastq

8.3 Assembly

- Long-read first-pass assembler (choose one, Flye recommended):
   - flye --nano-raw filtered.fastq -g 5m -o flye_out --threads N
- Polish:
   - racon x2–3 iterations using raw reads (optional)
   - medaka_consensus with model matching chemistry:
   - medaka_consensus -i filtered.fastq -d flye_out/assembly.fasta -o medaka_out -m <r9.4.1_sup/r10_sup>
- Circularization and rotation (optional): circlator or simple heuristics to detect circular contigs.
- For hybrid (if Illumina available): Try Unicycler hybrid to improve small plasmids.

8.4 Contamination and QC checks

- Taxonomic check: kraken2 against RefSeq bacterial; report dominant species.
- Completeness: CheckM or BUSCO (bacteria).
- Coverage: map reads back with minimap2; compute depth (mosdepth).
- AMR/virulence screening: abricate with relevant databases; AMRFinderPlus.
- Multilocus sequence typing: mlst.

8.5 Deliverables

- Final assembly (FASTA)
- Polishing consensus (FASTA) and logs
- Per-sample FASTQ (raw and filtered)
- QC reports (NanoPlot, coverage, contamination)
- Metadata (sample IDs, barcodes, run conditions, software versions)

9. Quality control and acceptance criteria

- Apply thresholds in QC_Acceptance_Criteria.md (linked).
- Document deviations and justifications.

10. Documentation and data retention

- Maintain lab notebook entries (run ID, flow cell ID, pore count, kit lot numbers).
- Store raw data, intermediate files, and final outputs for ≥5 years or per policy.
- Backups: two geographically separate locations if possible.

11. Troubleshooting (selected)

- Low pore occupancy:
  - Check loading concentration; ensure no bubbles; verify priming steps.
- Low Q-scores:
  - DNA purity; gentle handling; correct basecalling model; avoid over-fragmentation.
- Poor assembly continuity:
  - Increase read N50 and coverage; consider ligation kit; perform additional polishing.

12. References

- ONT protocols (latest chemistry manuals)
- Flye, Medaka, Dorado documentation
- Community best practices for ONT bacterial assembly

Appendix A: Example commands

- See Section 8 for templates; adjust threads, genome size, and models.