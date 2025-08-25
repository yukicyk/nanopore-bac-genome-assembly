# ================================================================= #
#                         RULE: ASSEMBLY                            #
# ================================================================= #
# These rules perform de novo genome assembly.
# - Flye is used for ONT or hybrid assemblies.
# - SPAdes is used for Illumina-only assemblies.

rule flye:
    input:
        reads=lambda wc: SAMPLES_DF.loc[wc.sample, "ont_reads"]
    output:
        # We only care about the final assembly FASTA.
        assembly="results/{sample}/assembly/flye/assembly.fasta"
    params:
        # Get read type from config, e.g., "nano-hq"
        read_type=config["flye"]["read_type"],
        # Flye needs an output directory to write its many files.
        outdir="results/{sample}/assembly/flye/"
    log:
        "logs/assembly/flye/{sample}.log"
    threads: 16
    conda:
        "../envs/flye.yaml"
    shell:
        "flye --{params.read_type} {input.reads} "
        "--out-dir {params.outdir} --threads {threads} &> {log}"

rule spades:
    input:
        # Get R1 and R2 from the sample sheet.
        r1=lambda wc: SAMPLES_DF.loc[wc.sample, "illumina_r1"],
        r2=lambda wc: SAMPLES_DF.loc[wc.sample, "illumina_r2"]
    output:
        # SPAdes produces scaffolds.fasta, which is the file we want.
        assembly="results/{sample}/assembly/spades/scaffolds.fasta"
    params:
        outdir="results/{sample}/assembly/spades/"
    log:
        "logs/assembly/spades/{sample}.log"
    threads: 16
    conda:
        "../envs/spades.yaml" # Assuming you have a spades.yaml
    shell:
        "spades.py --pe1-1 {input.r1} --pe1-2 {input.r2} "
        "--outdir {params.outdir} --threads {threads} --careful &> {log}"