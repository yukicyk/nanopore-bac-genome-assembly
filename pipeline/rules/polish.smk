# ================================================================= #
#                         RULE: POLISHING                           #
# ================================================================= #
# These rules polish the draft assembly to improve base-level accuracy.
# - Medaka uses ONT reads.
# - Pilon uses Illumina reads for the final polish.

rule medaka:
    input:
        assembly="results/{sample}/assembly/flye/assembly.fasta",
        reads=lambda wc: SAMPLES_DF.loc[wc.sample, "ont_reads"]
    output:
        assembly="results/{sample}/polish/medaka/consensus.fasta"
    params:
        outdir=lambda wildcards, output: os.path.dirname(output.assembly)
    log:
        "logs/polish/medaka/{sample}.log"
    threads: 8
    conda:
        "../envs/polish.yaml"
    shell:
        "medaka_consensus -i {input.reads} -d {input.assembly} "
        "-o {params.outdir} -t {threads} -m r941_min_sup_g507 &> {log}"

rule pilon:
    input:
        assembly="results/{sample}/polish/medaka/consensus.fasta",
        illumina_r1=lambda wc: SAMPLES_DF.loc[wc.sample, "illumina_r1"],
        illumina_r2=lambda wc: SAMPLES_DF.loc[wc.sample, "illumina_r2"]
    output:
        assembly="results/{sample}/polish/pilon/assembly.fasta"
    params:
        outdir=lambda wildcards, output: os.path.dirname(output.assembly),
        prefix="assembly",
        mem=config["pilon"]["mem"]
    log:
        "logs/polish/pilon/{sample}.log"
    threads: 12
    conda:
        "../envs/polish.yaml"
    shell:
        "# Step 1: Index assembly for mapping\n"
        "bwa index {input.assembly}\n"
        "# Step 2: Map Illumina reads to the assembly\n"
        "bwa mem -t {threads} {input.assembly} {input.illumina_r1} {input.illumina_r2} | "
        "samtools view -b - | samtools sort -o {params.outdir}/mapped_reads.bam\n"
        "# Step 3: Index the BAM file\n"
        "samtools index {params.outdir}/mapped_reads.bam\n"
        "# Step 4: Run Pilon\n"
        "pilon --genome {input.assembly} --frags {params.outdir}/mapped_reads.bam "
        "--output {params.prefix} --outdir {params.outdir} --threads {threads} "
        "--changes --verbose &> {log}"