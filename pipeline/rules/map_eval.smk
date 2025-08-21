rule map_reads:
  input:
    fa="results/{sample}/polish/final.fasta",
    fq=lambda wc: fastq(wc.sample)
  output:
    bam="results/{sample}/eval/reads.sorted.bam"
  conda: "../envs/map.yaml"
  threads: config["threads"]
  shell:
    "minimap2 -ax map-ont {input.fa} {input.fq} | samtools sort -o {output.bam} - && samtools index {output.bam}"

rule quast_eval:
  input:
    asm="results/{sample}/polish/final.fasta",
    ref=lambda wc: config.get('reference', '')
  output:
    "results/{sample}/eval/quast/report.tsv"
  conda: "../envs/qc.yaml"
  shell:
    "quast {input.asm} {('--reference ' + input.ref) if input.ref else ''} -o results/{wildcards.sample}/eval/quast"

rule depth_metrics:
  input: bam="results/{sample}/eval/reads.sorted.bam"
  output: "results/{sample}/eval/depth.tsv"
  conda: "../envs/map.yaml"
  shell:
    "bedtools genomecov -ibam {input.bam} -d > {output}"