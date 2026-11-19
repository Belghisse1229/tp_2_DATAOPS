#!/usr/bin/env bash
# Task 1.1 - inventory of the raw files (read-only on data/raw)
# crlf_lines: od -c shows each carriage return as the two characters \r; counting them
# gives the same result on Windows and Linux (awk and grep may drop or mis-read \r on Windows)
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
out=results/inventory.tsv
mkdir -p results
printf 'file\trecords\tfields_header\tlines_other_fields\tcrlf_lines\tfinal_newline\n' > "$out"
for f in data/raw/*.csv; do
  if [ "$(tail -c 1 "$f" | od -An -c | tr -d ' ')" = '\n' ]; then nl=yes; else nl=no; fi
  crlf=$(od -An -v -c "$f" | tr -s ' ' '\n' | grep -c '^\\r$' || true)
  awk -F, -v name="$(basename "$f")" -v nl="$nl" -v crlf="$crlf" '
    NR==1 { h = NF }
    NF != h { other++ }
    END { printf "%s\t%d\t%d\t%d\t%d\t%s\n", name, NR-1, h, other, crlf, nl }
  ' "$f" >> "$out"
done
cat "$out"
