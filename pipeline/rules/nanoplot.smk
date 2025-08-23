# ===================================================================
# ||              RULE FOR INITIAL RAW READ QC                     ||
# ===================================================================
# This rule uses NanoPlot to generate a quality control report for
# the raw input FASTQ files for each sample.

rule nanoplot_qc:
    input:
        # Get the read path for a specific sample from our samples dataframe.
        reads=lambda wildcards: samples_df.loc[wildcards.sample, "read_path"]
    output:
        # Create a directory to store all NanoPlot output files.
        directory("results/{sample}/qc/nanoplot")
    params:
        # Optional: add a prefix for output files within the directory.
        prefix="{sample}_raw_qc"
    threads: 4
    conda:
        "../envs/nanoplot.yaml"
    log:
        "logs/nanoplot/{sample}.log"
    shell:
        """
        nanoplot \
            --threads {threads} \
            --fastq {input.reads} \
            --outdir {output} \
            --prefix {params.prefix} \
            --log_file {log}
        """