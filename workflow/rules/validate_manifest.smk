# ==============================
# File: workflow/rules/validate_manifest.smk
# ==============================
from pathlib import Path
import os
import json
import csv
import re

REPO = Path(os.environ.get("REPO_ROOT", Path(__file__).resolve().parents[2])).resolve()
DOC_TEMPLATE = (REPO / "docs" / "templates" / "run_manifest_template.tsv").resolve()

# Minimal fields for Schema A+ we expect to see at wet-lab time
CRITICAL_FIELDS = [
    "run_id",
    "run_date",
    "operator",
    "instrument_type",
    "device_id",
    "flowcell_id",
    "kit_code",
    "sample_id",
    "barcode_id",  # if multiplexed; will warn if missing when barcoding_kit not "none"
    "extraction_method",
    "dna_concentration_ng_per_uL",
]

RECOMMENDED_FIELDS = [
    "minknow_version",
    "dorado_or_guppy_version",
    "dorado_or_guppy_model",
    "basecalling_mode",
    "flowcell_chemistry",
    "flowcell_part",
    "barcoding_kit",
    "source_type",
    "sizing_method",
    "fragment_size_N50_kb",
    "raw_data_path",
    "fastq_output_path",
    "demux_output_path",
    "backup_paths",
    "checksum_manifest_path",
]

def _read_header(p):
    with open(p, "r", encoding="utf-8") as fh:
        line = fh.readline()
        if "\t" in line:
            delim = "\t"
        elif "," in line:
            delim = ","
        elif ";" in line:
            delim = ";"
        else:
            delim = "\t"
        headers = [h.strip() for h in line.rstrip("\n\r").split(delim)]
    return headers

rule validate_manifest:
    """
    Validate Schema A+ manifest(s) against the template, warn on missing critical/recommended fields.
    """
    output:
        report="reports/manifest_validation.txt",
        json="reports/manifest_validation.json",
    params:
        strict=lambda wc: bool(os.environ.get("VALIDATE_STRICT","").lower() in {"1","true","yes"}),
        # Allow overriding the glob in config.yaml: manifests_glob: "data/manifests/*.tsv"
        manifests_glob=lambda wc: config.get("manifests_glob", "data/manifests/*.tsv"),
    conda:
        "../envs/validate-manifest.yaml"
    threads: 1
    message:
        "Validating wet-lab manifests (Schema A+) -> {output.report}"
    run:
        import glob
        pattern = params.manifests_glob
        manifests = sorted(glob.glob(pattern))
        os.makedirs(Path(output.report).parent, exist_ok=True)
        issues = []
        summary = {"files":[],"critical_missing":{},"recommended_missing":{}}

        if not manifests:
            issues.append(f"WARNING: No manifests matched: {pattern}")
        else:
            template_headers = set(_read_header(str(DOC_TEMPLATE))) if DOC_TEMPLATE.exists() else set()
            for p in manifests:
                headers = set(_read_header(p))
                missing_critical = [c for c in CRITICAL_FIELDS if c not in headers]
                missing_recommended = [c for c in RECOMMENDED_FIELDS if c not in headers]
                # If a barcoding kit is declared in the manifest template but barcode_id is missing, warn
                if "barcoding_kit" in headers and "barcode_id" not in headers:
                    missing_recommended = sorted(set(missing_recommended + ["barcode_id"]))
                summary["files"].append({
                    "path": p,
                    "missing_critical": missing_critical,
                    "missing_recommended": missing_recommended,
                    "template_fields_present": len(template_headers & headers),
                    "template_fields_total": len(template_headers),
                })
                if missing_critical:
                    issues.append(f"{p}: MISSING CRITICAL fields: {', '.join(missing_critical)}")
                if missing_recommended:
                    issues.append(f"{p}: missing recommended fields: {', '.join(missing_recommended)}")

        with open(output.report, "w", encoding="utf-8") as fh:
            if DOC_TEMPLATE.exists():
                fh.write(f"Template: {DOC_TEMPLATE}\n\n")
            for line in (issues or ["All manifests present required critical fields."]):
                fh.write(line + "\n")

        for entry in summary["files"]:
            for c in entry["missing_critical"]:
                summary["critical_missing"][c] = summary["critical_missing"].get(c, 0) + 1
            for r in entry["missing_recommended"]:
                summary["recommended_missing"][r] = summary["recommended_missing"].get(r, 0) + 1
        with open(output.json, "w", encoding="utf-8") as jfh:
            json.dump(summary, jfh, indent=2)

        if params.strict and any(f["missing_critical"] for f in summary["files"]):
            raise ValueError("Critical fields missing in one or more manifests. See report.")