#!/usr/bin/env bash
# Task 1.2 - clean the web sample: drop hash_src_ip (column 6), remove quotes
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p data/clean
src=data/raw/web_2025-10.csv
out=data/clean/web_clean.csv
# Every line has exactly 6 plain comma fields (checked in 01), no comma inside a value,
# so cut is safe. The hash column is cut BEFORE anything else touches the data.
cut -d, -f1-5 "$src" | tr -d '"\r' > "$out"
echo "web_clean: $(wc -l < "$out") lines, $(awk -F, '{print NF}' "$out" | sort -u | tr '\n' ' ')fields"
