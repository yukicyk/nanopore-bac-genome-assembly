# ================================================================= #
#                         RULE: REPORTING                           #
# ================================================================= #
# This rule aggregates all QC results into a single MultiQC report.

rule multiqc:
    input:
        # Dynamically gather all possible QC outputs from all samples.
        expand(
            [
                "results/{sample}/qc/nanoplot/NanoPlot-report.html",
                "results/{sample}/qc/fastqc/",
                "results/{sample}/evaluation/quast/"
            ],
            sample=SAMPLES
        )
    output:
        "results/multiqc_report.html"
    log:
        "logs/multiqc.log"
    conda:
        "../envs/report.yaml"
    params:
        # Give the report a nice title.
        title="Bacterial WGS Pipeline Summary"
    shell:
        "multiqc . --filename {output} --title \"{params.title}\" --force &> {log}"