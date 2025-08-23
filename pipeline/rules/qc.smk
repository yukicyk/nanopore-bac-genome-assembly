# ===================================================================
# ||         RULES FOR ILLUMINA SHORT-READ QC (FASTQC)             ||
# ===================================================================
# This module runs FastQC on paired-end Illumina reads and then
# aggregates the results into a single MultiQC report.

# Identify which samples have Illumina data defined in the sample sheet.
# This assumes your samples_df has 'illumina_r1' and 'illumina_r2' columns.
# It filters out rows where the Illumina paths are empty or not defined.
SAMPLES_WITH_ILLUMINA = samples_df[
    samples_df["illumina_r1"].notna() & (samples_df["illumina_r1"] != "")
].index.tolist()


rule fastqc:
    """
    Run FastQC on paired-end Illumina reads for each sample that has them.
    """
    input:
        r1=lambda wildcards: samples_df.loc[wildcards.sample, "illumina_r1"],
        r2=lambda wildcards: samples_df.loc[wildcards.sample, "illumina_r2"]
    output:
        # FastQC creates both an HTML file and a ZIP archive.
        html_r1="results/{sample}/qc/fastqc/{sample}_R1_fastqc.html",
        zip_r1="results/{sample}/qc/fastqc/{sample}_R1_fastqc.zip",
        html_r2="results/{sample}/qc/fastqc/{sample}_R2_fastqc.html",
        zip_r2="results/{sample}/qc/fastqc/{sample}_R2_fastqc.zip",
    params:
        # Specify an output directory for clarity.
        outdir="results/{sample}/qc/fastqc"
    threads: 2
    conda:
        "../envs/fastqc.yaml"
    log:
        "logs/fastqc/{sample}.log"
    shell:
        """
        # Ensure the output directory exists before running
        mkdir -p {params.outdir}

        fastqc \
            --threads {threads} \
            --outdir {params.outdir} \
            {input.r1} {input.r2} > {log} 2>&1
        """


rule multiqc:
    """
    Aggregate all FastQC reports into a single, comprehensive MultiQC report.
    """
    input:
        # Gather all the FastQC zip files from all samples that have Illumina reads.
        expand(
            "results/{sample}/qc/fastqc/{sample}_{read}_fastqc.zip",
            sample=SAMPLES_WITH_ILLUMINA,
            read=["R1", "R2"]
        )
    output:
        "reports/multiqc_report.html"
    conda:
        "../envs/fastqc.yaml"
    log:
        "logs/multiqc.log"
    shell:
        """
        multiqc \
            --force \
            --title "Short Read QC Report" \
            --outdir reports \
            . > {log} 2>&1
        """