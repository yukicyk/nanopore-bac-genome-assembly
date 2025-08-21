rule assemble_flye:
  input: fq=lambda wc: fastq(wc.sample)
  output: asm="results/{sample}/assembly/flye/assembly.fasta"
  conda: "../envs/assemble.yaml"
  threads: config["threads"]
  shell:
    "flye --nano-raw {input.fq} --out-dir results/{wildcards.sample}/assembly/flye "
    "--threads {threads} --genome-size 3m && "
    "cp results/{wildcards.sample}/assembly/flye/assembly.fasta {output.asm}"

rule assemble_canu:
  input: fq=lambda wc: fastq(wc.sample)
  output: asm="results/{sample}/assembly/canu/contigs.fasta"
  conda: "../envs/assemble.yaml"
  threads: config["threads"]
  shell:
    "canu -p {wildcards.sample} -d results/{wildcards.sample}/assembly/canu "
    "genomeSize=3m -nanopore-raw {input.fq} useGrid=false "

rule assemble:
  input: lambda wc: fastq(wc.sample)
  output: "results/{sample}/assembly/assembly.fasta"
  run:
    import shutil, os
    assembler = config.get("assembler", "flye")
    if assembler == "canu":
      asm = f"results/{wildcards.sample}/assembly/canu/contigs.fasta"
      shell("snakemake -j1 --cores 1 results/{wildcards.sample}/assembly/canu/contigs.fasta")
    else:
      asm = f"results/{wildcards.sample}/assembly/flye/assembly.fasta"
      shell("snakemake -j1 --cores 1 results/{wildcards.sample}/assembly/flye/assembly.fasta")
    os.makedirs(os.path.dirname(output[0]), exist_ok=True)
    shutil.copyfile(asm, output[0])