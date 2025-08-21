import sys, pandas as pd, os
quast, depth, ann = snakemake.input["quast"], snakemake.input["depth"], snakemake.input["ann"]
out = snakemake.output[0]
# parse key metrics from QUAST tsv and depth stats; count CDS from GFF
# write a concise Markdown report with versions (from conda), inputs, outputs, and pass/fail vs acceptance criteria.