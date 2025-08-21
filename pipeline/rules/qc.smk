rule nanoplot_qc:
    input:
        reads=lambda w: config["samples"][w.sample]["read_path"]
    output:
        html="results/qc/{sample}/nanoplot/NanoPlot-report.html"
    params:
        outdir=lambda wildcards: f"results/qc/{wildcards.sample}/nanoplot"
    threads: 2
    conda: "pipeline/envs/qc.yaml"
    shell:
        """
        mkdir -p {params.outdir}
        NanoPlot --fastq {input.reads} --outdir {params.outdir} --threads {threads} --tsv_stats
        """