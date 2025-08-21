rule medaka_polish:
  input:
    asm="results/{sample}/assembly/assembly.fasta",
    fq=lambda wc: fastq(wc.sample)
  output:
    fa="results/{sample}/polish/medaka_consensus.fasta"
  conda: "../envs/polish.yaml"
  threads: config["threads"]
  shell:
    "minimap2 -ax map-ont {input.asm} {input.fq} | samtools sort -o results/{wildcards.sample}/polish/reads.bam - && "
    "samtools index results/{wildcards.sample}/polish/reads.bam && "
    "medaka_consensus -i {input.fq} -d {input.asm} -o results/{wildcards.sample}/polish -t {threads} && "
    "cp results/{wildcards.sample}/polish/consensus.fasta {output.fa}"

rule nanopolish_index:
  input: fq=lambda wc: fastq(wc.sample)
  output: touch("results/{sample}/polish/nanopolish.indexed")
  conda: "../envs/polish.yaml"
  shell: "nanopolish index {input} && touch {output}"

rule nanopolish_polish:
  input:
    asm="results/{sample}/assembly/assembly.fasta",
    fq=lambda wc: fastq(wc.sample),
    idx="results/{sample}/polish/nanopolish.indexed"
  output:
    fa="results/{sample}/polish/nanopolish_consensus.fasta"
  conda: "../envs/polish.yaml"
  threads: config["threads"]
  shell:
    "minimap2 -ax map-ont {input.asm} {input.fq} | samtools sort -o results/{wildcards.sample}/polish/np.bam - && "
    "samtools index results/{wildcards.sample}/polish/np.bam && "
    "python -m nanopolish_makerange {input.asm} | parallel -P {threads} "
    "'nanopolish variants --consensus results/{wildcards.sample}/polish/np.{{1}}.fa -w {{1}} "
    "-r {input.fq} -b results/{wildcards.sample}/polish/np.bam -g {input.asm} -t 1' && "
    "python -m nanopolish_merge {input.asm} results/{wildcards.sample}/polish/np.*.fa > {output.fa}"

rule polish:
  input: "results/{sample}/assembly/assembly.fasta"
  output: "results/{sample}/polish/final.fasta"
  run:
    pol = config.get("polisher", "medaka")
    src = f"results/{wildcards.sample}/polish/medaka_consensus.fasta" if pol in ["medaka","both"] else f"results/{wildcards.sample}/polish/nanopolish_consensus.fasta"
    if pol == "both":
      shell("snakemake -j1 results/{wildcards.sample}/polish/medaka_consensus.fasta")
      shell("snakemake -j1 results/{wildcards.sample}/polish/nanopolish_consensus.fasta")
      src = f"results/{wildcards.sample}/polish/medaka_consensus.fasta"
    import shutil, os
    os.makedirs(os.path.dirname(output[0]), exist_ok=True)
    shutil.copyfile(src, output[0])