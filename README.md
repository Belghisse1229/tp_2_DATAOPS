# TP2 — Open data pack (Nouakchott Open Data Desk)

- Student number (S): **251213**
- Focus ISP (last digit 3): **RIMATEL**
- Focus season (second-to-last digit 1): **Ligue 1 2021/2022**

## Sources

| Data | Repository | Pinned commit | Licence as published | Read on |
|---|---|---|---|---|
| Web traffic sample Oct 2025, match results 2007–2025 | https://github.com/binorassocies/rimdata | `e8666952ed3c52bbdff47411f7110b7fdc0dc297` | GNU GPL v3 (file `LICENSE` of the repository) | 2026-11-19 |
| Hassaniya corpus (d1 base, d2–d5 contributions, completed file) | https://github.com/Hassan-IA/DAH | `fc3e9a318fce778244056d2cb393448991e4f5d0` | CC-BY-4.0 (stated in the repository `README.md`) | 2026-11-19 |

The eight raw files are downloaded by `scripts/00_fetch.sh` and checked against `data/SHA256SUMS`.
`data/ref/client_class.csv` is a working classification made for this mission from the client name; it is not an industry standard.

## How to rebuild

```bash
git clone https://github.com/Belghisse1229/tp_2_DATAOPS.git && cd tp_2_DATAOPS
export S=251213
bash scripts/run_all.sh                       # fetch + checksum + every stage; log in logs/run.log
rm -rf data/clean results logs && S=$S bash scripts/run_all.sh    # full reset
```

Needs bash, coreutils (cut, sort, uniq, tr, wc, head, tail, od), grep, awk, curl, sha256sum and git. `run_all.sh` sets `LC_ALL=C` so that sorting is the same on every machine, and stops with a non-zero code if a checksum or a stage fails.

Stages: `00_fetch` → `01_inventory` → `02_web_clean` → `03_matches_clean` → `04_corpus_clean` → `05_web_profile` → `06_web_join` → `07_web_daily` → `08_league` → `09_corpus_profile`.

Work machine: Windows (MSYS2 UCRT64), gawk not available. Quoted CSV is read with a quote-aware parser written in plain awk (function `parse` in `04_corpus_clean.sh` and `09_corpus_profile.sh`) instead of gawk `FPAT`: a comma inside quotes stays in the field, `""` inside quotes becomes `"`, the outer quotes are removed. The busy-day threshold uses `sort -n` instead of gawk `asort`. Lines with a carriage return are counted with `grep -c $'\r'`, because awk on Windows reads files in text mode and drops `\r`.

Token rule for `hassaniya-en`: after lowercasing, a token is a maximal run of `[a-z0-9]`. Digits are kept because Hassaniya written in Latin letters (Arabizi) uses digits for Arabic sounds that have no Latin letter (`3` = ع, `7` = ح, `2` = ء, `9` = ق, `5` = خ, `4` = ذ); cutting on digits would split words like `3le` or `w7al`. Apostrophes, accents and punctuation are separators.

## Findings

### 1. Format problems of the raw files and their repair
**Claim:** All 8 raw files need repair before use: `matches.csv` has a carriage return on 2745 of 2745 lines; `dah_completed.csv` has a CR on 100 of its 101 lines, a fourth empty column and no final newline; `dah_d2`–`dah_d5` have no final newline; 323 of 3003 lines of `dah_d1.csv` split into another number of fields on a plain comma split because of quoted commas; every value of the web file is quoted.
**Evidence:** `results/inventory.tsv` (`scripts/01_inventory.sh`: `awk -F,` count of NF, `grep -c $'\r'`, `tail -c 1 | od -c`). Repairs: `tr -d '\r'`, `cut -d, -f1-5 | tr -d '"'` (web), quote-aware awk parser with `""` → `"` and trimming (corpus), each contribution file read on its own (never `cat`, which would glue a line without newline to the next header).
**Limit:** The inventory counts shapes, not meaning: it does not show empty values (3339 records without city), doubled quotes, the inner tab of one d1 line, spaces at the ends of fields, or dates without a year.

### 2. Match dates without a year
**Claim:** 154 of 2744 matches (all in Ligue 1 2024/2025) have a date without a year (`30.05.`); the working rule (months 08–12 → first year, 01–07 → second year) gives a wrong year for 57 of the 2326 full-dated matches of two-year seasons (2.45 %).
**Evidence:** `data/clean/matches_clean.csv` (`date_status`), output of `scripts/03_matches_clean.sh` in the log: Ligue 1 2019/2020 52 wrong (matches played in September–October 2020, after the COVID interruption), Championnat D1 2007/2008 5 wrong (matches in August 2008).
**Limit:** The rule fails when a season ends after July; it makes no error on the 86 full dates of 2024/2025, but the 154 inferred dates themselves cannot be checked with this file.

### 3. Unmapped web clients
**Claim:** 2430 of 45260 records (5.37 %) have a web client that is not in the lookup and get the class `unmapped`: `Other` 2361, `Google` 51, `Android` 15, `Apple Mail` 1, `Client` 1, `PDFExpert` 1.
**Evidence:** `results/isp_client_class.csv`, `data/clean/web_enriched.csv` (`scripts/06_web_join.sh`, awk left join `NR==FNR` with default `unmapped`); the join keeps 45261 lines, as many as `web_clean.csv`.
**Limit:** `Other` is a catch-all of the source: we do not know which clients it hides, so every share by class has an uncertainty of about 5 points.

### 4. Mobile share and bot share of the focus ISP (RIMATEL)
**Claim:** 499 of 4109 RIMATEL records (12.14 %) are of class `bot` (all `FacebookBot`), above the 4888 of 45260 (10.80 %) of the whole sample; 3380 of 4109 RIMATEL records (82.26 %) are iOS or Android, below the 85.51 % of the whole sample.
**Evidence:** `results/isp_client_class.csv` (row `RIMATEL,bot,499`), `results/web_daily_isp_251213.csv` (sum of `records`, `mobile`, `bot` for RIMATEL), `results/web_profile.txt` (`pct_mobile_all`).
**Limit:** `bot` is a working class based only on the client name, not a measure of automation: an automated client that calls itself a browser is counted as `browser`, and the 193 unmapped RIMATEL records (4.70 %) are not classified. The sample is a sample: we do not know how it was drawn.

