
# Data availability — Oral Treponema ONT WGS

## Overview

- This repository documents a research workflow for Oxford Nanopore bacterial genome assembly of oral Treponema isolates with GLP/GMP‑inspired recordkeeping.
- Public data are hosted by NCBI. This repo does not redistribute raw reads or assemblies.

## NCBI references

- BioProject: PRJNA284866 — Whole genome sequencing of oral treponemes
- Example submission: SUB5380773
- Access public metadata and sequences via the BioProject page and linked BioSamples/SRA runs.

## Per‑run mapping (publicly verifiable)

- The following barcode→BioSample mapping is provided for one documented run (date: 2019‑04‑01; “01042019” in wet‑lab notes). No patient identifiers are included.
- See evidence/run_20190401.tsv for a machine‑readable file.

## Transparency and constraints

- Only one verified mappings are included here, and made public ( the 2019‑04‑01 run) to demonstrate the workflow for the bioproject.
- Since the flowcell chemistry and packages for analysis have been updated, the current workflow in this repository is updated for future use.
- The exact workflow used in the bioproject is documented in the original logs and documents stored in evidencee/legacy_logs
- Other runs in this repository use mock manifests for demonstration and testing; they are clearly labeled as mock_*.tsv.
- Publication/IP: Some Treponema data remain under collaborators’ publication rights. This repo links to NCBI for public records and withholds non‑public sample mappings.

## UK data governance note

- No patient‑identifiable data are stored in this repository. Any clinical metadata are under institutional control elsewhere (UK GDPR compliant).
- This repository is for research/training and not for diagnostic use; for regulated use, operate within an accredited QMS and perform formal validation.