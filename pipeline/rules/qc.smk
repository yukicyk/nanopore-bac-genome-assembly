# ================================================================= #
#                         RULE: READ QC                             #
# ================================================================= #
# These rules perform initial quality control on the raw reads.
# - NanoPlot is run on ONT reads.
# - FastQC is run on Illumina reads.

# --- Helper function to get Illumina reads for a sample ---
def get_illumina_reads(wildcards):
    """Returns a list of Illumina read paths for a sample if they exist."""
    reads = []
    sample_info = SAMPLES_DF.loc[wildcards.sample]
    if pd.notna(sample_info.get("illumina_r1")) and sample_info.get("illumina_r1"):
        reads.append(sample_info["illumina_r1"])
    if pd.notna(sample_info.get("illumina_r2")) and sample_info.get("illumina_r2"):
        reads.append(sample_info["illumina_r2"])
    return reads

rule nanoplot:
    input:
        # This rule only runs if the sample has ONT reads.
        reads=lambda wc: SAMPLES_DF.loc[wc.sample, "ont_reads"]
    output:
        report=report("results/{sample}/qc/nanoplot/NanoPlot-report.html",
                      caption="../report/nanoplot.rst", category="QC")
    params:
        outdir="results/{sample}/qc/nanoplot"
    log:
        "logs/qc/nanoplot/{sample}.log"
    threads: 4
    conda:
        "../envs/nanoplot.yaml"
    shell:
        "NanoPlot --fastq {input.reads} --outdir {params.outdir} "
        "--threads {threads} &> {log}"

rule fastqc:
    input:
        # This rule only runs if the sample has Illumina reads.
        reads=get_illumina_reads
    output:
        # FastQC creates one report per input file.
        html=expand("results/{{sample}}/qc/fastqc/{read_pair}_fastqc.html",
                    read_pair=["R1", "R2"])
    params:
        outdir="results/{sample}/qc/fastqc"
    log:
        "logs/qc/fastqc/{sample}.log"
    threads: 2
    conda:
        "../envs/fastqc.yaml"
    shell:
        "fastqc --outdir {params.outdir} --threads {threads} {input.reads} &> {log}"

# ================================================================= #
#                         RULE: READ QC                             #
# ================================================================= #
# These rules perform initial quality control on the raw reads.
# - NanoPlot is run on ONT reads.
# - FastQC is run on Illumina reads.

# --- Helper function to get Illumina reads for a sample ---
def get_illumina_reads(wildcards):
    """Returns a list of Illumina read paths for a sample if they exist."""
    reads = []
    sample_info = SAMPLES_DF.loc[wildcards.sample]
    if pd.notna(sample_info.get("illumina_r1")) and sample_info.get("illumina_r1"):
        reads.append(sample_info["illumina_r1"])
    if pd.notna(sample_info.get("illumina_r2")) and sample_info.get("illumina_r2"):
        reads.append(sample_info["illumina_r2"])
    return reads

rule nanoplot:
    input:
        # This rule only runs if the sample has ONT reads.
        reads=lambda wc: SAMPLES_DF.loc[wc.sample, "ont_reads"]
    output:
        report=report("results/{sample}/qc/nanoplot/NanoPlot-report.html",
                      caption="../report/nanoplot.rst", category="QC")
    params:
        outdir="results/{sample}/qc/nanoplot"
    log:
        "logs/qc/nanoplot/{sample}.log"
    threads: 4
    conda:
        "../envs/nanoplot.yaml"
    shell:
        "NanoPlot --fastq {input.reads} --outdir {params.outdir} "
        "--threads {threads} &> {log}"

rule fastqc:
    input:
        # This rule only runs if the sample has Illumina reads, support paired-end reads only.
        reads=get_illumina_reads
    output:
        # FastQC creates one report per input file.
        html=expand("results/{{sample}}/qc/fastqc/{read_pair}_fastqc.html",
                    read_pair=["R1", "R2"])
    params:
        outdir="results/{sample}/qc/fastqc"
    log:
        "logs/qc/fastqc/{sample}.log"
    threads: 2
    conda:
        "../envs/fastqc.yaml"
    shell:
        "fastqc --outdir {params.outdir} --threads {threads} {input.reads} &> {log}"