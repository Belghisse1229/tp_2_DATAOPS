#!/usr/bin/env bash
# Usage: S=<your student number> bash scripts/run_all.sh
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C                      # the same sort order on every machine
: "${S:?export S=<your student number> first}"
export S
mkdir -p logs data/clean results/tables
LOG=logs/run.log
log()   { printf '%s %s\n' "$(date -u +%FT%TZ)" "$*" | tee -a "$LOG" >&2; }
stage() { log "START $1"; bash "scripts/$1" || { log "FAILED $1"; exit 1; }; log "DONE $1"; }

stage 00_fetch.sh            # download if missing + sha256 check (stops on mismatch)
stage 01_inventory.sh        # M1 task 1.1
stage 02_web_clean.sh        # M1 task 1.2
stage 03_matches_clean.sh    # M1 task 1.3
stage 04_corpus_clean.sh     # M1 task 1.4
stage 05_web_profile.sh      # M2 task 2.1
stage 06_web_join.sh         # M2 task 2.2
stage 07_web_daily.sh        # M2 task 2.3
stage 08_league.sh           # M2 task 2.4
stage 09_corpus_profile.sh   # M2 task 2.5
log "ALL DONE"
