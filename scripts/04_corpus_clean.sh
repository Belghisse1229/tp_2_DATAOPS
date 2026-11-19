#!/usr/bin/env bash
# Task 1.4 - quoted CSV -> TSV with a quote-aware parser written in plain awk
# (gawk/FPAT not available on this machine; the parser follows the same CSV rules)
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p data/clean

# awk program shared by the conversion and the check:
# splits $0 into fld[1..nf], respecting quotes; "" inside quotes = one "
PARSER='
function parse(line,    i, c, inq, cur) {
  nf = 0; cur = ""; inq = 0
  for (i = 1; i <= length(line); i++) {
    c = substr(line, i, 1)
    if (c == "\"") {
      if (inq && substr(line, i + 1, 1) == "\"") { cur = cur "\""; i++ }  # doubled quote
      else inq = !inq                                                   # open/close quotes
    } else if (c == "," && !inq) { fld[++nf] = cur; cur = "" }          # field separator
    else cur = cur c
  }
  fld[++nf] = cur
  return nf
}'

csv2tsv() {   # $1 = source csv ; keeps the first 3 fields
  tr -d '\r' < "$1" | awk -v OFS='\t' "$PARSER"'
    {
      parse($0)
      for (i = 1; i <= 3; i++) {
        v = (i <= nf) ? fld[i] : ""
        gsub(/^[ \t]+|[ \t]+$/, "", v)       # trim spaces and tabs at both ends
        gsub(/\t/, " ", v)                   # an inner tab would break the TSV
        f[i] = v
      }
      print f[1], f[2], f[3]
    }'
}
csv2tsv data/raw/dah_d1.csv        > data/clean/hass_base.tsv
csv2tsv data/raw/dah_completed.csv > data/clean/hass_completed.tsv

# Check: fields per line seen by the parser on d1 and d3 (must be one value: 3)
for f in dah_d1 dah_d3; do
  printf '%s parser field counts: ' "$f"
  tr -d '\r' < data/raw/$f.csv | awk "$PARSER"' { print parse($0) }' | sort -u | tr '\n' ' '; echo
done
for f in hass_base hass_completed; do
  printf '%s: %s lines, TSV field counts: ' "$f" "$(wc -l < data/clean/$f.tsv)"
  awk -F'\t' '{print NF}' data/clean/$f.tsv | sort -u | tr '\n' ' '; echo
done
