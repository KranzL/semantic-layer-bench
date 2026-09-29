#!/bin/sh
for RUN in "$@"; do
  echo "=== starting $RUN $(date) ==="
  caffeinate -i ./replicate.sh "$RUN"
  echo "=== finished $RUN $(date) ==="
  (cd .. && git add "results/runs/$RUN" && git commit -m "Add replication run $RUN results" 2>&1 | tail -n 1)
done
echo "ALL_RUNS_DONE $(date)"
