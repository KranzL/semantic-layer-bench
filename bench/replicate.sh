#!/bin/sh
cd "$(dirname "$0")"
RUN="${1:-r2}"
BASE="../results/runs/$RUN"
LOG="$BASE/logs/pipeline.out"
mkdir -p "$BASE/logs"
./setup_runtime.sh >> "$LOG" 2>&1
todo="${BUILD_MODELS-muse haiku sonnet opus fable}"
attempt=0
while [ -n "$todo" ] && [ "$attempt" -lt 4 ]; do
  attempt=$((attempt + 1))
  echo "BUILD attempt $attempt: $todo" >> "$LOG"
  for m in $todo; do
    ../.venv/bin/python run_builds.py --run "$RUN" --models "$m" >> "$BASE/logs/build-$m.out" 2>&1 &
  done
  wait
  todo=$(../.venv/bin/python -c "
import json, sys
last = {}
for l in open('$BASE/builds.jsonl'):
    r = json.loads(l)
    last[r['model']] = r
print(' '.join(m for m in 'muse haiku sonnet opus fable'.split() if m not in last or last[m].get('limited')))")
  [ -n "$todo" ] && echo "BUILD limited, retrying in 30 min: $todo" >> "$LOG" && sleep 1800
done
echo "BUILDS_DONE" >> "$LOG"
while true; do
  ../.venv/bin/python run_queries.py --run "$RUN" --concurrency 6 >> "$BASE/logs/queries.out" 2>&1
  left=$(../.venv/bin/python -c "
import sys
sys.path.insert(0, '.')
from common import latest_rows
print(1050 - len(latest_rows('$BASE/queries.jsonl')))")
  echo "REMAINING $left" >> "$LOG"
  [ "$left" -le 0 ] && break
  sleep 1800
done
../.venv/bin/python report.py --inp "$BASE/queries.jsonl" > /dev/null 2>&1
../.venv/bin/python compare_runs.py --b "$BASE/queries.jsonl" --out "$BASE/comparison.md" > /dev/null 2>&1
echo "PIPELINE_DONE" >> "$LOG"
