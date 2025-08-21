rule summary_report:
  input:
    quast="results/{sample}/eval/quast/report.tsv",
    depth="results/{sample}/eval/depth.tsv",
    ann="results/{sample}/annot/prokka/PROKKA.gff"
  output:
    "results/{sample}/report/{sample}_summary.md"
  conda: "../envs/qc.yaml"
  script:
    "../../scripts/assembly_qc_summary.py"