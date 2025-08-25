# ================================================================= #
#                       RULE: ANNOTATION                            #
# ================================================================= #
# This file contains rules for genome annotation. The user can choose
# between Bakta or Prokka in the config.yaml file.

import os

# ================================================================= #
#          DETERMINE THE CORRECT BAKTA DATABASE PATH              #
# ================================================================= #

# Get the base path and type from the config file.
BAKTA_DB_BASE_PATH = config["bakta_db"]
BAKTA_DB_TYPE = config.get("bakta_db_type", "light")
EXPECTED_SUBDIR = f"db-{BAKTA_DB_TYPE}"

# Logic to determine the final, correct database path.
# Case 1: The user provided a direct path that already ends with 'db-light' or 'db-full'.
if BAKTA_DB_BASE_PATH.rstrip("/").endswith(EXPECTED_SUBDIR):
    # The path is already complete. Use it as is.
    BAKTA_DB_PATH = BAKTA_DB_BASE_PATH
# Case 2: The user provided a parent directory.
else:
    # We need to append the subdirectory. Use os.path.join for safety.
    BAKTA_DB_PATH = os.path.join(BAKTA_DB_BASE_PATH, EXPECTED_SUBDIR)

# Now, BAKTA_DB_PATH is our "single source of truth".
# All rules below will refer to this variable.

rule download_bakta_db:
    output:
        # The output is always the final, correct path.
        directory(BAKTA_DB_PATH)
    params:
        # The download command still needs the parent directory.
        outdir=BAKTA_DB_BASE_PATH,
        db_type=BAKTA_DB_TYPE
    log:
        "logs/setup/download_bakta_db.log"
    conda:
        "../envs/bakta.yaml"
    shell:
        # The download command will place the database inside the output directory.
        # We redirect all output (stdout and stderr) to the log file.
        "bakta_db download --output {output} --type {params.db_type} &> {log}"

rule bakta:
    input:
        assembly=get_final_assemblies,
        # The database is now a formal input dependency.
        # Snakemake will run the rule that produces this directory first.
        db=BAKTA_DB_PATH
    output:
        gbff="results/{sample}/annotation/bakta/{sample}.gbff"
    params:
        outdir="results/{sample}/annotation/bakta",
        prefix="{sample}"
    log:
        "logs/annotation/bakta/{sample}.log"
    threads: 16
    conda:
        "../envs/bakta.yaml"
    shell:
        # Use '{input.db}' to refer to the database path.
        "bakta --db {input.db} {input.assembly} "
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