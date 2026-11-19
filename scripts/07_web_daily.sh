#!/usr/bin/env bash
# Task 2.3 - one row per (national ISP, day of October 2025), busy_flag = nearest-rank P90
# (no gawk asort: the 31 daily counts are sorted with sort -n)
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
: "${S:?export S first}"
out=results/web_daily_isp_$S.csv

# 1) 124 rows isp,date,records,mobile,bot - every day created, empty day = 0
rows=$(awk -F, -v OFS=, '
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
  }' data/clean/web_enriched.csv)

# 2) one threshold per ISP: sort its 31 counts ascending, take rank ceil(0.9 n)
thr=""
for i in CHINGUITEL MATTEL MAURITEL RIMATEL; do
  counts=$(printf '%s\n' "$rows" | awk -F, -v i="$i" '$1==i{print $3}' | sort -n)
  n=$(printf '%s\n' "$counts" | wc -l)
  rank=$(awk -v n="$n" 'BEGIN{r = int(0.9*n); if (r < 0.9*n) r++; print r}')
  t=$(printf '%s\n' "$counts" | awk -v r="$rank" 'NR==r')
  echo "$i P90 threshold (rank $rank of $n): $t" >&2
  thr="$thr$i,$t
"
done

# 3) busy_flag = records >= threshold of its own ISP
{ echo "isp,date,records,mobile,bot,busy_flag"
  printf '%s' "$thr" | awk -F, -v OFS=, '
    NR==FNR { if ($1 != "") t[$1] = $2; next }
    { print $0, ($3+0 >= t[$1]+0 ? 1 : 0) }' - <(printf '%s\n' "$rows")
} > "$out"
echo "$out: $(awk 'END{print NR-1}' "$out") data rows"
echo "busy days:"; awk
run bash scripts/07_web_daily.sh
awk -F, '$1=="RIMATEL"{print $3}' results/web_daily_isp_251213.csv | sort -n | tr '\n' ' '; echo
awk -F, '$1=="RIMATEL"{r+=$3; m+=$4; b+=$5} END{print "records",r,"mobile",m,"bot",b}' results/web_daily_isp_251213.csv
t=$(awk -F, '$1=="RIMATEL"{print $3}' results/web_daily_isp_251213.csv | sort -n | awk 'NR==28')
days=$(awk -F, '$1=="RIMATEL" && $6==1{printf "%s(%s) ", $2, $3}' results/web_daily_isp_251213.csv)
echo "NOTE 2.3 I observed a RIMATEL P90 threshold of $t (rank 28 of 31) and busy days: $days, so each ISP is judged on its own volume; with n=31 and rank 28 at least 4 days are always busy by construction; it does not show why these days are busy (the start-of-month peak may come from the sampling)." | tee -a "$LOG"
cat > scripts/08_league.sh <<'EOF'
#!/usr/bin/env bash
# Task 2.4 - league tables per season, season summary, result distribution
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C
m=data/clean/matches_clean.csv
mkdir -p results/tables
rm -f results/tables/*.csv
tail -n +2 "$m" | cut -d, -f1 | sort -u | while IFS= read -r season; do
  file="results/tables/$(printf '%s' "$season" | tr ' /' '__').csv"
  { echo "team,played,goals_for,goals_against,diff,points"
    awk -F, -v s="$season" -v OFS=, '
      $1==s { h=$4; a=$5; hg=$6+0; ag=$7+0
              p[h]++; p[a]++; gf[h]+=hg; ga[h]+=ag; gf[a]+=ag; ga[a]+=hg
              if (hg>ag) pt[h]+=3; else if (hg<ag) pt[a]+=3; else { pt[h]++; pt[a]++ } }
      END { for (t in p) print t, p[t], gf[t], ga[t], gf[t]-ga[t], pt[t]+0 }' "$m" \
    | sort -t, -k6,6nr -k5,5nr -k3,3nr -k1,1
  } > "$file"
done
{ echo "season,teams,matches,expected_matches,complete"
  awk -F, -v OFS=, 'NR>1 { n[$1]++; if (!(($1 SUBSEP $4) in seen)) { seen[$1 SUBSEP $4]; t[$1]++ }
                                  if (!(($1 SUBSEP $5) in seen)) { seen[$1 SUBSEP $5]; t[$1]++ } }
    END { for (s in n) { e = t[s]*(t[s]-1); print s, t[s], n[s], e, (n[s]==e ? "yes" : "no") } }' "$m" | sort -t, -k1,1
} > results/season_summary.csv
{ echo "result,matches"
  tail -n +2 "$m" | cut -d, -f8 | sort | uniq -c | sort -k1,1nr -k2,2 | awk '{print $2","$1}'
} > results/result_distribution.csv
echo "tables: $(ls results/tables | wc -l) files"
cat results/season_summary.csv; cat results/result_distribution.csv
