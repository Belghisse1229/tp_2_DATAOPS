#!/usr/bin/env bash
# Task 2.3 - one row per (national ISP, day of October 2025), busy_flag = nearest-rank P90
# portable version: temporary files in data/clean (ignored by git), sort -n instead of gawk asort
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
: "${S:?export S first}"
out=results/web_daily_isp_$S.csv
mkdir -p data/clean results
rowsf=data/clean/daily_rows.tmp
thrf=data/clean/daily_thr.tmp
cntf=data/clean/daily_counts.tmp

# 1) 124 rows isp,date,records,mobile,bot - every day created, empty day = 0
awk -F, -v OFS=, '
  NR>1 { k = $3 SUBSEP $1; r[k]++
         if ($4=="iOS" || $4=="Android") m[k]++
         if ($6=="bot") b[k]++ }
  END {
    split("CHINGUITEL MATTEL MAURITEL RIMATEL", isp, " ")
    for (i = 1; i <= 4; i++)
      for (d = 1; d <= 31; d++) {
        day = sprintf("2025-10-%02d", d); k = isp[i] SUBSEP day
        print isp[i], day, r[k]+0, m[k]+0, b[k]+0
      }
  }' data/clean/web_enriched.csv > "$rowsf"

# 2) one threshold per ISP: its 31 counts sorted ascending, value at rank ceil(0.9 n)
: > "$thrf"
for i in CHINGUITEL MATTEL MAURITEL RIMATEL; do
  awk -F, -v i="$i" '$1==i{print $3}' "$rowsf" | sort -n > "$cntf"
  n=$(awk 'END{print NR}' "$cntf")
  rank=$(awk -v n="$n" 'BEGIN{r = int(0.9*n); if (r < 0.9*n) r++; print r}')
  t=$(awk -v r="$rank" 'NR==r' "$cntf")
  echo "$i P90 threshold (rank $rank of $n): $t"
  echo "$i,$t" >> "$thrf"
done

# 3) busy_flag = records >= threshold of its own ISP
{ echo "isp,date,records,mobile,bot,busy_flag"
  awk -F, -v OFS=, 'NR==FNR { t[$1] = $2; next }
                    { print $0, ($3+0 >= t[$1]+0 ? 1 : 0) }' "$thrf" "$rowsf"
} > "$out"
rm -f "$rowsf" "$thrf" "$cntf"
echo "$out: $(awk 'END{print NR-1}' "$out") data rows"
echo "busy days:"; awk -F, '$6==1{print "  "$1, $2, $3}' "$out"
