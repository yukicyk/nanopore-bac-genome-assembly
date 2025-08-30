# File: rules/plasmid.smk

# This rule uses MOB-suite to identify and characterize plasmid contigs
# from the final, polished assembly.

rule mob_suite_recon:
    input:
        # Use the helper function to get the correct final assembly path
        # This automatically handles ONT-only, hybrid, and Illumina-only cases.
        fasta=get_final_assemblies,
    output:
        report="results/{sample}/plasmid/mob_suite/contig_report.txt",
        results_dir=directory("results/{sample}/plasmid/mob_suite/"),
    params:
        db=config["tools"]["plasmid_detection"]["mob_db_path"],
        prefix="{sample}",
    log:
        "logs/mob_suite/{sample}.log",
    conda:
        "../envs/plasmid.yaml"
    threads: 8
    shell:
        """
        mob_recon --infile {input.fasta} \
            --outdir {output.results_dir} \
            --db {params.db} \
            --threads {threads} \
            --force &> {log}
        """