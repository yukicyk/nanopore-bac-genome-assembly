#
# pipeline/rules/assemble.smk
# Handles de novo assembly. Supports multiple assemblers via config.
#

rule assemble_flye:
    input:
        reads=get_reads
    output:
        asm="results/assembly/{sample}/flye/assembly.fasta"
    threads: config.get("threads", {}).get("flye", 8)
    conda: "envs/flye.yaml"
    params:
        genome_size=config.get("genome_size", "4.6m"),
        outdir="results/assembly/{sample}/flye"
    shell:
        """
        flye --nano-raw {input.reads} --genome-size {params.genome_size} --threads {threads} --out-dir {params.outdir}
        # Normalize output name
        if [ -f "{params.outdir}/assembly.fasta.gz" ]; then
            gzip -dc "{params.outdir}/assembly.fasta.gz" > "{output.asm}"
        elif [ ! -f "{output.asm}" ]; then
            echo "Flye did not produce the expected assembly file." >&2; exit 1
        fi
        """

# Add other assemblers here if needed, e.g., Canu
# rule assemble_canu: ...

def get_assembly_input(wildcards):
    """Selects the output of the chosen assembler."""
    assembler = config.get("assembler", "flye")
    return f"results/assembly/{wildcards.sample}/{assembler}/assembly.fasta"

rule assembly_final:
    input:
        get_assembly_input
    output:
        "results/assembly/{sample}/assembly.fasta"
    shell:
        "ln -sr {input} {output}"