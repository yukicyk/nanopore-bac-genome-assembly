#
# pipeline/rules/evaluation.smk
# Handles evaluation of the final assembly.
#

rule map_reads_to_final_assembly:
    input:
        asm="results/polish/{sample}/final_assembly.fasta",
        reads=get_reads
    output:
        bam="results/evaluation/{sample}/coverage.bam",
        bai="results/evaluation/{sample}/coverage.bam.bai"
    threads: config.get("threads", {}).get("minimap2", 8)
    conda: "envs/map.yaml" # Assumes a map.yaml with minimap2 and samtools
    shell:
        """
        minimap2 -ax map-ont -t {threads} {input.asm} {input.reads} | \
        samtools sort -@ {threads} -o {output.bam}
        samtools index {output.bam}
        """

rule quast:
    input:
        asm="results/polish/{sample}/final_assembly.fasta",
        ref=REF # Global reference from main Snakefile
    output:
        directory("results/evaluation/{sample}/quast")
    threads: config.get("threads", {}).get("quast", 4)
    conda: "envs/quast.yaml"
    shell: "quast --output-dir {output} --threads {threads} -r {input.ref} {input.asm}"

rule depth_summary:
    input:
        bam="results/evaluation/{sample}/coverage.bam"
    output:
        "results/evaluation/{sample}/depth.txt"
    conda: "envs/map.yaml"
    shell:
        """
        samtools depth -a {input.bam} | \
        awk '{{sum+=$3; n++}} END {{if(n>0) print "Mean depth:", sum/n; else print "Mean depth: 0"}}' > {output}
        """