#!/bin/sh
cd "$(dirname "$0")"
LOG=../results/logs/queries.out
while true; do
  ../.venv/bin/python run_queries.py --concurrency 6 >> $LOG 2>&1
  left=$(../.venv/bin/python -c "
import json
done = set()
for l in open('../results/queries.jsonl'):
    r = json.loads(l)
    if not r.get('limited'):
        done.add((r['model'], r['layer'], r['qid']))
print(1050 - len(done))")
  echo "REMAINING $left" >> $LOG
  [ "$left" -le 0 ] && break
  sleep 1800
done
echo PIPELINE_DONE >> $LOG
