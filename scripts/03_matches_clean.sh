#!/usr/bin/env bash
# Task 1.3 - clean the match results, ISO dates, result, date_status; test the year rule
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
mkdir -p data/clean
src=data/raw/matches.csv
out=data/clean/matches_clean.csv
tr -d '\r' < "$src" | awk -F, -v OFS=, '
  NR==1 { print "season,date,date_status,home_team,away_team,home_goals,away_goals,result"; next }
  {
    split($2, d, ".")                       # d[1]=day d[2]=month d[3]=year (maybe empty)
    if (d[3] ~ /^[0-9][0-9][0-9][0-9]$/) { y = d[3]; st = "full" }
    else {
      # working rule: season "... Y1/Y2": months 08-12 -> Y1, months 01-07 -> Y2
      if (match($1, /([0-9][0-9][0-9][0-9])\/([0-9][0-9][0-9][0-9])$/)) {
        y1 = substr($1, RSTART, 4); y2 = substr($1, RSTART+5, 4)
        y = (d[2]+0 >= 8) ? y1 : y2
      } else { print "no year for row " NR > "/dev/stderr"; exit 1 }
      st = "inferred"
    }
    r = ($5 > $6) ? "home_win" : (($5 < $6) ? "away_win" : "draw")
    print $1, y "-" d[2] "-" d[1], st, $3, $4, $5, $6, r
  }' > "$out"
echo "matches_clean: $(awk 'END{print NR-1}' "$out") rows; inferred: $(awk -F, '$3=="inferred"' "$out" | wc -l)"

# Test of the working rule on full dates of two-year seasons (no file is changed)
echo "Rule test (full dates, two-year seasons): season tested wrong"
awk -F, 'NR>1 && $3=="full" && match($1, /[0-9][0-9][0-9][0-9]\/[0-9][0-9][0-9][0-9]$/) {
    y1 = substr($1, RSTART, 4); y2 = substr($1, RSTART+5, 4)
    m = substr($2, 6, 2) + 0; guess = (m >= 8) ? y1 : y2
    t[$1]++; tot++
    if (guess != substr($2, 1, 4)) { w[$1]++; bad++ }
  }
  END { for (s in t) printf "  %s %d %d\n", s, t[s], w[s]+0
        printf "  TOTAL %d %d\n", tot, bad }' "$out" | sort
