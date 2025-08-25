# ================================================================= #
#                       RULE: EVALUATION                            #
# ================================================================= #
# This rule evaluates the quality of the final assembly using QUAST.
import os

rule quast:
    input:
        assembly=get_final_assemblies
    output:
        report="results/{sample}/evaluation/quast/report.html"
    params:
        # No outdir needed in params, can be derived in shell command
        # or specified directly if QUAST requires it.
        # Let's derive it from the output for clarity.
        outdir=lambda wildcards, output: os.path.dirname(output.report)
    log:
        "logs/evaluation/quast/{sample}.log"
    threads: 8
    conda:
        "../envs/quast.yaml"
    shell:
        "quast.py --output-dir {params.outdir} --threads {threads} "
        "{input.assembly} &> {log}"