#!/usr/bin/env bash
# Task 2.5 - (a) corpus profile, (b) translation backlog
# (no gawk: contribution files are parsed with a quote-aware parser in plain awk)
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
b=data/clean/hass_base.tsv
out=results/hass_profile.txt
mkdir -p results data/clean
# ---- (a) profile ------------------------------------------------------------
awk -F'\t' 'NR>1 { n++; c[$1]++
    s = tolower($1); w += gsub(/[a-z]+/, "&", s) }        # English word = run of a-z
  END { for (e in c) { d++; if (c[e] > 1) { rep++; extra += c[e]-1 } }
        printf "sentence_pairs: %d\n", n
        printf "distinct_english_sentences: %d\n", d
        printf "english_sentences_appearing_more_than_once: %d\n", rep
        printf "extra_rows_from_repeats: %d\n", extra
        printf "avg_words_per_english_sentence: %.2f (%d words / %d sentences)\n", w/n, w, n }' "$b" > "$out"
# English words: lowercase, every maximal run of a-z on its own line, stoplist removed
tail -n +2 "$b" | cut -f1 | tr 'A-Z' 'a-z' | tr -cs 'a-z' '\n' | grep -v '^$' \
  | grep -vxE 'a|an|the|to|of|is|i|you|he|she|it|and|in|my' \
  | sort | uniq -c | sort -k1,1nr -k2,2 | awk 'NR<=10' \
  | awk '{printf "top_english_word_%d: %s %d\n", NR, $2, $1}' >> "$out"
# hassaniya-en (Arabizi): allowed characters a-z and 0-9 (digits 2 3 4 5 7 9 stand for Arabic letters)
tok=data/clean/hass_tokens.tmp
tail -n +2 "$b" | cut -f3 | tr 'A-Z' 'a-z' | tr -cs 'a-z0-9' '\n' | grep -v '^$' > "$tok"
printf "hassaniya_en_tokens_total: %d\n" "$(wc -l < "$tok")" >> "$out"
printf "hassaniya_en_tokens_with_digit: %d\n" "$(grep -c '[0-9]' "$tok")" >> "$out"
printf "hassaniya_en_distinct_tokens_with_digit: %d\n" "$(grep '[0-9]' "$tok" | sort -u | wc -l)" >> "$out"
sort "$tok" | uniq -c | sort -k1,1nr -k2,2 | awk 'NR<=10' \
  | awk '{printf "top_hassaniya_en_token_%d: %s %d\n", NR, $2, $1}' >> "$out"
rm -f "$tok"
cat "$out"
# ---- (b) backlog --------------------------------------------------------------
PARSER='
function parse(line,    i, c, inq, cur) {
  nf = 0; cur = ""; inq = 0
  for (i = 1; i <= length(line); i++) {
    c = substr(line, i, 1)
    if (c == "\"") {
      if (inq && substr(line, i + 1, 1) == "\"") { cur = cur "\""; i++ }
      else inq = !inq
    } else if (c == "," && !inq) { fld[++nf] = cur; cur = "" }
    else cur = cur c
  }
  fld[++nf] = cur
  return nf
}'
contrib=data/clean/contrib.tmp
# each contribution file is parsed on its own (no cat: a missing final newline would glue lines)
for x in 2 3 4 5; do
  tr -d '\r' < data/raw/dah_d$x.csv | awk -v OFS='\t' "$PARSER"'
    FNR==1 { next }                                   # skip the header of each file
    { parse($0)
      for (i = 1; i <= 3; i++) { v = (i <= nf) ? fld[i] : ""
        gsub(/^[ \t]+|[ \t]+$/, "", v); gsub(/\t/, " ", v); f[i] = v }
      print f[1], f[2], f[3] }'
done > "$contrib"
awk -F'\t' -v OFS='\t' '
  FILENAME == ARGV[1] { if (FNR>1) base[$1]; next }
  FILENAME == ARGV[2] { if (FNR>1) { car[$1] = $2; cen[$1] = $3 }; next }
  FNR==1 && FILENAME == ARGV[3] { print "english", "hassaniya_ar", "hassaniya_en", "status" }
  { if ($1 in base)               st = "in_base"
    else if ($1 in car)         { st = "filled"; $2 = car[$1]; $3 = cen[$1] }
    else if ($2 != "" && $3 != "") st = "prefilled"
    else                          st = "todo"
    print $1, $2, $3, st }
' data/clean/hass_base.tsv data/clean/hass_completed.tsv "$contrib" > data/clean/hass_backlog.tsv
rm -f "$contrib"
{ echo "status,rows"; tail -n +2 data/clean/hass_backlog.tsv | cut -f4 | sort | uniq -c | awk '{print $2","$1}'; } > results/backlog_status.csv
echo "hass_backlog: $(awk 'END{print NR-1}' data/clean/hass_backlog.tsv) rows"; cat results/backlog_status.csv
