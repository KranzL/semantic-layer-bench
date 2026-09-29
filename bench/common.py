import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DBT_SRC = os.path.join(ROOT, "relay_dbt")
WAREHOUSE = os.path.join(ROOT, "data", "warehouse.duckdb")
HIDDEN = os.path.join(ROOT, "hidden")
RESULTS = os.path.join(ROOT, "results")
LAYERS_DIR = os.path.join(ROOT, "build", "layers")
RUNTIME = os.environ.get("RELAY_RUNTIME", "/private/tmp/relay")
RUN_BIN = os.path.join(RUNTIME, "py", "bin")
VENV_BIN = os.path.join(ROOT, ".venv", "bin")
TOOL_BIN = RUN_BIN if os.path.exists(os.path.join(RUN_BIN, "dbt")) else VENV_BIN
MODELS = ["muse", "haiku", "sonnet", "opus", "fable"]
LAYERS = ["none", "reference"] + MODELS


def latest_rows(path):
    import json
    rows = {}
    if os.path.exists(path):
        for line in open(path):
            r = json.loads(line)
            rows[(r["model"], r["layer"], r["qid"])] = r
    return {k: v for k, v in rows.items() if not v.get("limited")}
