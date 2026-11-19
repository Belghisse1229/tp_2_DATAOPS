#!/usr/bin/env bash
# Task 2.2 - left join web_clean x client_class on web_client (unmatched -> unmapped)
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
awk -F, -v OFS=, '
  NR==FNR { if (FNR>1) cls[$1] = $2; next }       # 1st file: lookup table
  FNR==1  { print $0, "client_class"; next }
  { print $0, (($5 in cls) ? cls[$5] : "unmapped") }
' data/ref/client_class.csv data/clean/web_clean.csv > data/clean/web_enriched.csv
{ echo "isp,client_class,records"
  tail -n +2 data/clean/web_enriched.csv | awk -F, '{c[$3","$6]++} END{for (k in c) print k","c[k]}' \
    | sort -t, -k1,1 -k2,2
} > results/isp_client_class.csv
echo "web_enriched: $(wc -l < data/clean/web_enriched.csv) lines (web_clean: $(wc -l < data/clean/web_clean.csv))"
echo "unmapped clients:"; awk -F, '$6=="unmapped"{c[$5==""?"(empty)":$5]++} END{for(k in c) print "  "c[k], k}' data/clean/web_enriched.csv | sort -k1,1nr
echo "class totals:"; tail -n +2 data/clean/web_enriched.csv | cut -d, -f6 | sort | uniq -c
