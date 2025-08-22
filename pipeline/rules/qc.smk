#
# pipeline/rules/qc.smk
# Handles initial read quality control for all samples.
#

rule nanoplot_qc:
    input:
        # This rule should only run for ONT samples.
        reads=lambda wc: SAMPLES_DF.loc[wc.sample, "read_path"] if SAMPLES_DF.loc[wc.sample, "platform"] == "ont" else []
    output:
        report=touch("results/qc/{sample}/nanoplot/NanoPlot-report.html")
    params:
        outdir="results/qc/{sample}/nanoplot"
    threads: config.get("threads", {}).get("nanoplot", 4)
    conda: "envs/ont-qc.yaml"
    shell:
        """
        # Only run if input is not empty
        if [ -z "{input.reads}" ]; then exit 0; fi
        NanoPlot --fastq {input.reads} --outdir {params.outdir} --threads {threads}
        """

# Placeholder for Illumina QC - we can implement this fully in the next phase.
rule fastqc:
    input:
        r1=lambda wc: SAMPLES_DF.loc[wc.sample, "read_path_r1"] if SAMPLES_DF.loc[wc.sample, "platform"] == "illumina" else [],
        r2=lambda wc: SAMPLES_DF.loc[wc.sample, "read_path_r2"] if SAMPLES_DF.loc[wc.sample, "platform"] == "illumina" else []
    output:
        touch("results/qc/{sample}/fastqc/fastqc.ok")
    params:
        outdir="results/qc/{sample}/fastqc"
    threads: 2
    conda: "envs/qc.yaml" # Assumes a qc.yaml with fastqc
    shell:
        """
        # Only run if input is not empty
        if [ -z "{input.r1}" ]; then exit 0; fi
        mkdir -p {params.outdir}
        # fastqc {input.r1} {input.r2} -o {params.outdir}
        touch {output} # Placeholder command
        """