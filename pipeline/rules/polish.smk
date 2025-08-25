# ================================================================= #
#                         RULE: POLISHING                           #
# ================================================================= #
# These rules polish the draft assembly to improve base-level accuracy.
# - Medaka uses ONT reads.
# - Pilon uses Illumina reads for the final polish.

rule medaka:
    input:
        # Takes the Flye assembly and the raw ONT reads.
        assembly="results/{sample}/assembly/flye/assembly.fasta",
        reads=lambda wc: SAMPLES_DF.loc[wc.sample, "ont_reads"]
    output:
        assembly="results/{sample}/polish/medaka/consensus.fasta"
    params:
        outdir="results/{sample}/polish/medaka"
    log:
        "logs/polish/medaka/{sample}.log"
    threads: 8
    conda:
        "../envs/polish.yaml" # Assuming a general polish env
    shell:
        "medaka_consensus -i {input.reads} -d {input.assembly} "
        "-o {params.outdir} -t {threads} -m r941_min_sup_g507 &> {log}"

rule pilon:
    input:
        # Takes the Medaka-polished assembly and Illumina reads.
        assembly="results/{sample}/polish/medaka/consensus.fasta",
        illumina_r1=lambda wc: SAMPLES_DF.loc[wc.sample, "illumina_r1"],
        illumina_r2=lambda wc: SAMPLES_DF.loc[wc.sample, "illumina_r2"]
    output:
        # Pilon's final output is named based on the --output prefix.
        assembly="results/{sample}/polish/pilon/assembly.fasta"
    params:
        outdir="results/{sample}/polish/pilon",
        prefix="assembly",
        mem=config["pilon"]["mem"]
    log:
        "logs/polish/pilon/{sample}.log"
    threads: 12
    conda:
        "../envs/polish.yaml" # Assuming a general polish env
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