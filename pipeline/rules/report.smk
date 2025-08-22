#
# pipeline/rules/report.smk
# Generates a final summary report for all samples.
#

rule generate_summary_report:
    input:
        # Gather all the required reports from every sample in the run
        quast_reports=expand("results/evaluation/{sample}/quast/report.tsv", sample=SAMPLES),
        depth_reports=expand("results/evaluation/{sample}/depth.txt", sample=SAMPLES),
        # Conditionally include GFF files only if annotation is enabled
        gff_files=expand("results/annotation/{sample}/prokka/{sample}.gff", sample=SAMPLES) if USE_PROKKA else []
    output:
        "reports/assembly_summary_report.md"
    conda:
        "envs/report.yaml"
    script:
        "../scripts/assembly_qc_summary.py"