# ================================================================= #
#                       RULE: EVALUATION                            #
# ================================================================= #
# This rule evaluates the quality of the final assembly using QUAST.
import os

rule quast:
    input:
        assembly=get_final_assemblies
    output:
        directory("results/{sample}/evaluation/quast")
    params:
       outdir=lambda wildcards, output: output
    log:
        "logs/evaluation/quast/{sample}.log"
    threads: 8
    conda:
        "../envs/quast.yaml"
    shell:
        "quast.py --output-dir {params.outdir} --threads {threads} "
        "{input.assembly} &> {log}"