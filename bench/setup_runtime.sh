#!/bin/sh
set -e
RUNTIME="${RELAY_RUNTIME:-/private/tmp/relay}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$RUNTIME"
if [ ! -x "$RUNTIME/py/bin/python" ]; then
  "$ROOT/.venv/bin/python" -m venv "$RUNTIME/py"
  "$RUNTIME/py/bin/pip" install -q -r "$ROOT/requirements.lock"
fi
"$RUNTIME/py/bin/python" -c "import duckdb, dbt, metricflow; print('runtime ok')"
