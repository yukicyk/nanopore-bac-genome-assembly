rule prokka:
  input: fa="results/{sample}/polish/final.fasta"
  output: "results/{sample}/annot/prokka/PROKKA.gff"
  conda: "../envs/annotate.yaml"
  shell:
    "prokka --outdir results/{wildcards.sample}/annot/prokka --prefix {wildcards.sample} {input.fa}"
    