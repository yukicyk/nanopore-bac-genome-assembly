# ================================================================= #
#                         RULE: READ QC                             #
# ================================================================= #



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