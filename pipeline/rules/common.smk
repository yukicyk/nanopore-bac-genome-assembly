# ================================================================= #
#                    pipeline/rules/common.smk                      #
# ================================================================= #
# This file contains all the python functions in the pipeline for improved readability.

import pandas as pd 

# This class is used in the main Snakefile to generate final file paths.
class MockWildcards:
    def __init__(self, sample):
        self.sample = sample

# originally from Snakefile, global helper functions moved here
def has_data(series):
    """Helper function to check for a valid, non-empty string path."""
    return pd.notna(series) & (series != '')

def get_final_assemblies(wildcards):
    """
    Inspects the sample sheet for a given sample and returns the path
    to its expected final assembly file based on the data present.
    """
    sample_info = SAMPLES_DF.loc[wildcards.sample]
    has_ont = wildcards.sample in ONT_SAMPLES
    has_illumina = wildcards.sample in ILLUMINA_SAMPLES

    if has_ont and has_illumina:
        return f"results/{wildcards.sample}/polish/pilon/assembly.fasta"
    elif has_ont:
        return f"results/{wildcards.sample}/polish/medaka/consensus.fasta"
    elif has_illumina:
        return f"results/{wildcards.sample}/assembly/spades/scaffolds.fasta"
    else:
        raise ValueError(f"Sample {wildcards.sample} has no reads defined.")

def get_final_annotation(wildcards):
    """
    Inspects the config and returns the path to the expected final
    annotation file based on the chosen annotator.
    """
    annotator = config.get("annotation", {}).get("tool", "bakta").lower()
    if annotator == "prokka":
        return f"results/{wildcards.sample}/annotation/prokka/{wildcards.sample}.gff"
    else: # Default to bakta
        return f"results/{wildcards.sample}/annotation/bakta/{wildcards.sample}.gbff"

# Originally from qc.smk, moved here for modularity
# --- Helper function to get ONT reads for a sample ---
def get_ont_reads(wildcards):
    """
    Returns the path to ONT reads for a given sample.
    This function is robust against missing values (NaN) and empty strings.
    If no valid path is found, it returns an empty list, causing Snakemake to skip.
    """
    sample_info = SAMPLES_DF.loc[wildcards.sample]
    ont_path = sample_info.get("ont_reads")

    # This check handles NaN, None, and empty strings ('').
    # It only returns the path if it is a string with content.
    if ont_path and isinstance(ont_path, str):
        return ont_path
    else:
        # Returning an empty list is a safe way to tell Snakemake to skip.
        return []

# --- Helper function to get Illumina reads for a sample ---
def get_illumina_reads(wildcards):
    """
    Returns a list of Illumina read paths for a sample.
    This function is robust against missing values (NaN) and empty strings.
    If the sample has no Illumina reads, it returns an empty list.
    """
    reads = []
    sample_info = SAMPLES_DF.loc[wildcards.sample]

    r1_path = sample_info.get("illumina_r1")
    if r1_path and isinstance(r1_path, str):
        reads.append(r1_path)

    r2_path = sample_info.get("illumina_r2")
    if r2_path and isinstance(r2_path, str):
        reads.append(r2_path)
    
    return reads