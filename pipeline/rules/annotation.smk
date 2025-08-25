# ================================================================= #
#                       RULE: ANNOTATION                            #
# ================================================================= #
# This file contains rules for genome annotation. The user can choose
# between Bakta or Prokka in the config.yaml file.

rule bakta:
    input:
        assembly=get_final_assemblies
    output:
        # This path must match the output of get_final_annotation for 'bakta'
        gbff="results/{sample}/annotation/bakta/{sample}.gbff"
    params:
        outdir="results/{sample}/annotation/bakta",
        prefix="{sample}",
        db=config["bakta"]["db_path"]
    log:
        "logs/annotation/bakta/{sample}.log"
    threads: 16
    conda:
        "../envs/bakta.yaml"
    shell:
        "bakta --db {params.db} {input.assembly} "
        "--output {params.outdir} --prefix {params.prefix} "
        "--threads {threads} --force &> {log}"


rule prokka:
    input:
        assembly=get_final_assemblies
    output:
        # This path must match the output of get_final_annotation for 'prokka'
        gff="results/{sample}/annotation/prokka/{sample}.gff"
    params:
        outdir="results/{sample}/annotation/prokka",
        prefix="{sample}",
        kingdom=config["prokka"]["kingdom"]
    log:
        "logs/annotation/prokka/{sample}.log"
    threads: 8
    conda:
        "../envs/prokka.yaml" 
    shell:
        "prokka --outdir {params.outdir} --prefix {params.prefix} "
        "--kingdom {params.kingdom} --cpus {threads} "
        "--force {input.assembly} &> {log}"