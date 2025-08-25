# ================================================================= #
#                         RULE: READ QC                             #
# ================================================================= #
import os

# --- QC Rules ---

rule nanoplot:
    input:
        reads=get_ont_reads
    output:
        report=touch("results/{sample}/qc/nanoplot/NanoPlot-report.html")
    params:
        # Dynamically get the output directory from the output file
        outdir=lambda wildcards, output: os.path.dirname(output.report)
    log:
        "logs/qc/nanoplot/{sample}.log"
    threads: config["threads"]["filtlong"]
    conda:
        "../envs/nanoplot.yaml"
    shell:
        "NanoPlot --fastq {input.reads} --outdir {params.outdir} "
        "--threads {threads} &> {log}"

rule fastqc:
    input:
        reads=get_illumina_reads
    output:
        directory("results/{sample}/qc/fastqc")
    params:
        # FastQC needs a directory, derive it from the output flag file's location
        outdir="{output}"
    log:
        "logs/qc/fastqc/{sample}.log"
    threads: 2
    conda:
        "../envs/fastqc.yaml"
    shell:
        "fastqc --outdir {params.outdir} --threads {threads} {input.reads} &> {log}"