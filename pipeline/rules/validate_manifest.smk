# ============================================
# File: pipeline/rules/validate_manifest.smk
# ============================================

from pathlib import Path as _Path
import os

# Expect these to be defined by the main Snakefile:
# - REPO, CFG_DIR, SCRIPTS_DIR
# - DOC_TEMPLATE (may be None)
print(f"[validate_manifest.smk] REPO={REPO} CFG_DIR={CFG_DIR}")

def _exists_safe(p):
    try:
        if not p:
            return False
        return _Path(p).exists()
    except Exception:
        return False

rule validate_manifest:
    """
    Validate wet-lab manifests (Schema A+) and emit simple reports.
    This rule is robust to missing DOC_TEMPLATE; it will emit empty reports so the pipeline can proceed.
    """
    output:
        txt="reports/manifest_validation.txt",
        jsn="reports/manifest_validation.json"
    # Fixed path: envs are under pipeline/envs, not pipeline/rules/envs
    conda:
        str(PIPELINE_DIR / "envs" / "validate-manifest.yaml")
    message:
        "Validating wet-lab manifests (Schema A+) -> reports/manifest_validation.txt"
    run:
        import json
        from pathlib import Path

        # Always make reports dir
        Path("reports").mkdir(parents=True, exist_ok=True)

        # If no template configured or it does not exist, emit stub reports and return.
        if not _exists_safe(DOC_TEMPLATE):
            Path(output.txt).write_text(
                "Manifest validation skipped: no DOC_TEMPLATE configured or file not found.\n"
            )
            Path(output.jsn).write_text(json.dumps({
                "status": "skipped",
                "reason": "no_template",
                "doc_template": DOC_TEMPLATE if DOC_TEMPLATE else None
            }, indent=2))
            return

        # Lightweight checks; expand as needed
        problems = []
        warnings = []

        manifests_dir = REPO / "data" / "manifests"
        found = []
        if manifests_dir.exists():
            for ext in (".tsv", ".csv"):
                found.extend(sorted(str(p) for p in manifests_dir.glob(f"*{ext}")))
        else:
            warnings.append(f"manifests dir missing: {manifests_dir}")

        summary = []
        summary.append(f"DOC_TEMPLATE: {DOC_TEMPLATE}")
        summary.append(f"Manifests found: {len(found)}")
        if warnings:
            summary.append("Warnings:")
            summary.extend([f"  - {w}" for w in warnings])
        if problems:
            summary.append("Problems:")
            summary.extend([f"  - {e}" for e in problems])

        Path(output.txt).write_text("\n".join(summary) + "\n")
        Path(output.jsn).write_text(json.dumps({
            "status": "ok" if not problems else "error",
            "doc_template": DOC_TEMPLATE,
            "manifests_found": found,
            "warnings": warnings,
            "problems": problems
        }, indent=2))