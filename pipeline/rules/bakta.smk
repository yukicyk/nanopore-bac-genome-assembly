# pipeline/rules/bakta.smk

# Rule to download the bakta database if it doesn't exist
rule bakta_download_db:
    output:
        touch(f"{config['resources']['bakta_db']}/db.done")
    params:
        db_path=config["resources"]["bakta_db"]
    conda:
        "../envs/bakta.yaml"
    shell:
        "bakta_db --output {params.db_path} --force"

# Rule to run bakta annotation
rule bakta_annotate:
    input:
        assembly="results/{sample}/polishing/medaka/{sample}.fasta",
        db_done=f"{config['resources']['bakta_db']}/db.done"
    output:
        directory("results/{sample}/annotation/bakta")
    params:
        db_path=config["resources"]["bakta_db"],
        prefix="{sample}"
    threads: 8
    conda:
        "../envs/bakta.yaml"
    log:
        "logs/bakta/{sample}.log"
    shell:
        "bakta --db {params.db_path} "
        "--output {output} "
        "--prefix {params.prefix} "
        "--threads {threads} "
        "{input.assembly} > {log} 2>&1"