rule compile_samples:
    input:
        "data/manifests/run_20190401.tsv"
    output:
        "config/samples.tsv"
    shell:
        """
        python scripts/manifest_to_samples.py --manifests_glob 'data/manifests/*.tsv' --out {output}
        """
