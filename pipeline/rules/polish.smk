#
# pipeline/rules/polish.smk
# Handles assembly polishing.
#

# --- Racon Polishing ---
rule map_for_racon_r1:
    input:
        asm="results/assembly/{sample}/assembly.fasta",
        reads=get_reads
    output:
        temp("results/polish/{sample}/r1.paf.gz")
    threads: config.get("threads", {}).get("minimap2", 8)
    conda: "envs/polish.yaml"
    shell: "minimap2 -x map-ont -t {threads} {input.asm} {input.reads} | gzip -c > {output}"

rule racon_r1:
    input:
        draft="results/assembly/{sample}/assembly.fasta",
        reads=get_reads,
        paf="results/polish/{sample}/r1.paf.gz"
    output:
        "results/polish/{sample}/racon1.fasta"
    threads: config.get("threads", {}).get("racon", 8)
    conda: "envs/polish.yaml"
    shell: "racon -t {threads} {input.reads} {input.paf} {input.draft} > {output}"

# You can chain a second round of Racon similarly if needed.

# --- Medaka Polishing ---
rule medaka:
    input:
        asm="results/polish/{sample}/racon1.fasta", # Input is Racon-polished assembly
        reads=get_reads
    output:
        directory("results/polish/{sample}/medaka")
    threads: config.get("threads", {}).get("medaka", 8)
    conda: "envs/medaka.yaml"
    params:
        model=config.get("medaka_model", "r104_e81_sup_g615")
    shell:
        "medaka_consensus -i {input.reads} -d {input.asm} -o {output} -t {threads} -m {params.model}"

# --- Final Polished Assembly Selection ---
def get_final_polished_assembly(wildcards):
    """Selects the final polished assembly based on config."""
    # For now, we assume Medaka is the final step. This can be expanded.
    return "results/polish/{wildcards.sample}/medaka/consensus.fasta"

rule polish_final:
    input:
        get_final_polished_assembly
    output:
        "results/polish/{sample}/final_assembly.fasta"
    shell:
        "cp {input} {output}"