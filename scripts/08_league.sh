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
