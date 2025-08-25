# ================================================================= #
#                       RULE: EVALUATION                            #
# ================================================================= #
# This rule evaluates the quality of the final assembly using QUAST.

rule quast:
    input:
        # This uses the helper function from the main Snakefile
        # to get the correct final assembly for the sample.
        assembly=get_final_assemblies
    output:
        report="results/{sample}/evaluation/quast/report.html"
    params:
        outdir="results/{sample}/evaluation/quast"
    log:
        "logs/evaluation/quast/{sample}.log"
    threads: 8
    conda:
        "../envs/quast.yaml"
    shell:
        "quast.py --output-dir {params.outdir} --threads {threads} "
        "-o {params.outdir} {input.assembly} &> {log}"