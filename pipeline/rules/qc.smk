# ================================================================= #
#                         RULE: READ QC                             #
# ================================================================= #

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

# --- QC Rules ---

rule nanoplot:
    input:
        reads=get_ont_reads
    output:
        # Using touch to create a placeholder file for the report
        report=touch("results/{sample}/qc/nanoplot/NanoPlot-report.html")
    params:
        outdir="results/{sample}/qc/nanoplot"
    log:
        "logs/qc/nanoplot/{sample}.log"
    threads: config["threads"]["filtlong"] # A reasonable default
    conda:
        "../envs/nanoplot.yaml" # Assumed path
    shell:
        "NanoPlot --fastq {input.reads} --outdir {params.outdir} "
        "--threads {threads} &> {log}"

rule fastqc:
    input:
        reads=get_illumina_reads
    output:
        # Using a flag file to mark completion, since FastQC creates a directory
        done=touch("results/{sample}/qc/fastqc.done")
    params:
        outdir="results/{sample}/qc/fastqc"
    log:
        "logs/qc/fastqc/{sample}.log"
    threads: 2
    conda:
        "../envs/fastqc.yaml" # Assumed path
    shell:
        "fastqc --outdir {params.outdir} --threads {threads} {input} &> {log}"