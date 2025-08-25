# ================================================================= #
#                       RULE: ANNOTATION                            #
# ================================================================= #
# This file contains rules for genome annotation. The user can choose
# between Bakta or Prokka in the config.yaml file.

rule bakta:
    input:
        assembly=get_final_assemblies
    output:
        gbff="results/{sample}/annotation/bakta/{sample}.gbff"
    params:
        outdir="results/{sample}/annotation/bakta",
        prefix="{sample}",
        # --- CORRECTED LINE ---
        # Use .get() for safe access. If config['bakta'] doesn't exist,
        # this will return None instead of causing a KeyError.
        db=config.get("bakta", {}).get("db_path")
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
        gff="results/{sample}/annotation/prokka/{sample}.gff"
    params:
        outdir="results/{sample}/annotation/prokka",
        prefix="{sample}",
        # --- CORRECTED LINE ---
        # Same for prokka for consistency and robustness.
        kingdom=config.get("prokka", {}).get("kingdom", "Bacteria")
    log:
        "logs/annotation/prokka/{sample}.log"
    threads: 8
    conda:
        "../envs/prokka.yaml"
    shell:
        "prokka --outdir {params.outdir} --prefix {params.prefix} "
        "--kingdom {params.kingdom} --cpus {threads} "
        "--force {input.assembly} &> {log}"