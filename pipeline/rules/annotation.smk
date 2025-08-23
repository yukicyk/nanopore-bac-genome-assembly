#
# pipeline/rules/annotation.smk
# Handles genome annotation.
#

rule annotate_prokka:
    input:
        asm="results/polish/{sample}/final_assembly.fasta"
    output:
        gff="results/annotation/{sample}/prokka/{sample}.gff"
    threads: config.get("threads", {}).get("annotate", 8)
    conda: "envs/annotate_prokka.yaml"
    params:
        outdir="results/annotation/{sample}/prokka",
        prefix="{sample}"
    shell:
        "prokka --outdir {params.outdir} --prefix {params.prefix} --cpus {threads} {input.asm}"

# Add Bakta rule similarly if needed
# rule annotate_bakta: ...