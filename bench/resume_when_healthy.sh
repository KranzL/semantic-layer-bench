#!/bin/sh
cd "$(dirname "$0")"
RUN="${1:-r2}"
LOG="../results/runs/$RUN/logs/pipeline.out"
ok=0
while [ "$ok" -lt 2 ]; do
  secs=$(../.venv/bin/python - <<'PY'
import subprocess, time
t = time.time()
try:
    subprocess.run(["claude", "-p", "Reply with the single word ok.", "--model", "sonnet", "--safe-mode", "--no-session-persistence"], input="", capture_output=True, text=True, timeout=120)
    print(int(time.time() - t))
except subprocess.TimeoutExpired:
    print(999)
PY
)
  echo "HEALTH sonnet ${secs}s $(date '+%H:%M')" >> "$LOG"
  if [ "$secs" -lt 60 ]; then ok=$((ok + 1)); else ok=0; fi
  [ "$ok" -lt 2 ] && sleep 900
done
echo "HEALTHY, resuming" >> "$LOG"
BUILD_MODELS="" exec caffeinate -i ./replicate.sh "$RUN"
