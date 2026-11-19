#!/usr/bin/env bash
# Task 2.1 - profile of the web sample
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
w=data/clean/web_clean.csv
out=results/web_profile.txt
mkdir -p results
awk -F, 'NR>1 {
    n++; os[$4]++; if ($2 == "") nocity++
    if ($4 != "") known++
    if ($4 == "iOS") ios++; if ($4 == "Android") andr++
  }
  END {
    nos = 0; for (o in os) nos++
    printf "records: %d\n", n
    printf "distinct_os_name_values (empty counts as a value): %d\n", nos
    printf "records_without_city: %d\n", nocity
    printf "pct_without_city: %.2f%% (denominator %d records)\n", 100*nocity/n, n
    printf "pct_ios_all: %.2f%% (%d / %d all records)\n", 100*ios/n, ios, n
    printf "pct_android_all: %.2f%% (%d / %d all records)\n", 100*andr/n, andr, n
    printf "pct_mobile_all: %.2f%% (%d / %d all records)\n", 100*(ios+andr)/n, ios+andr, n
    printf "pct_ios_known_os: %.2f%% (%d / %d records with known os_name)\n", 100*ios/known, ios, known
    printf "pct_android_known_os: %.2f%% (%d / %d records with known os_name)\n", 100*andr/known, andr, known
    printf "pct_mobile_known_os: %.2f%% (%d / %d records with known os_name)\n", 100*(ios+andr)/known, ios+andr, known
  }' "$w" > "$out"
# five most frequent web_client (ties: name A-Z)
tail -n +2 "$w" | cut -d, -f5 | sort | uniq -c | sort -k1,1nr -k2 | awk 'NR<=5' \
  | awk '{c=$1; sub(/^ *[0-9]+ /, ""); printf "top_web_client_%d: %s %d\n", NR, ($0==""?"(empty)":$0), c}' >> "$out"
cat "$out"
# daily os counts: count desc, then date, then os_name
{ echo "date,os_name,count"
  tail -n +2 "$w" | awk -F, '{c[$1","$4]++} END{for (k in c) print k","c[k]}' \
    | sort -t, -k3,3nr -k1,1 -k2,2
} > results/daily_os_counts.csv
echo "daily_os_counts.csv: $(wc -l < results/daily_os_counts.csv) lines"; head -4 results/daily_os_counts.csv
