#!/usr/bin/env bash
# Task 1.1 - inventory of the raw files (read-only on data/raw)
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
out=results/inventory.tsv
mkdir -p results
printf 'file\trecords\tfields_header\tlines_other_fields\tcrlf_lines\tfinal_newline\n' > "$out"
for f in data/raw/*.csv; do
  # last byte of the file: a newline or not
  if [ "$(tail -c 1 "$f" | od -An -c | tr -d ' ')" = '\n' ]; then nl=yes; else nl=no; fi
  # awk counts the last line even without a final newline, so NR-1 = data rows
  awk -F, -v name="$(basename "$f")" -v nl="$nl" '
    NR==1 { h = NF }
    NF != h { other++ }
    /\r/    { crlf++ }
    END { printf "%s\t%d\t%d\t%d\t%d\t%s\n", name, NR-1, h, other, crlf, nl }
  ' "$f" >> "$out"
done
cat "$out"
