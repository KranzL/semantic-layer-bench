import argparse
import collections
import glob
import json
import math
import os
import platform
import re
import shutil
import subprocess
import sys
import tempfile

import duckdb

from common import DBT_SRC, HIDDEN, LAYERS, MODELS, RESULTS, ROOT, TOOL_BIN, VENV_BIN, WAREHOUSE, latest_rows
from grade import grade
from make_layer import make_layer
from truth import compute, load_questions

MANIFEST = os.path.join(RESULTS, "manifest.json")
TOOLS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tools")
REFERENCE_CHECKS = {
    "q01": ["--metrics", "mrr", "--start-time", "2025-06-30", "--end-time", "2025-06-30"],
    "q03": ["--metrics", "paying_customers", "--start-time", "2025-03-31", "--end-time", "2025-03-31"],
    "q05": ["--metrics", "logo_churn", "--start-time", "2025-05-31", "--end-time", "2025-05-31"],
    "q07": ["--metrics", "billings", "--start-time", "2025-01-01", "--end-time", "2025-03-31"],
    "q09": ["--metrics", "recognized_revenue", "--start-time", "2025-03-01", "--end-time", "2025-03-31"],
    "q11": ["--metrics", "cash_collected", "--start-time", "2025-06-01", "--end-time", "2025-06-30"],
    "q12": ["--metrics", "refunds", "--start-time", "2024-01-01", "--end-time", "2024-12-31"],
    "q13": ["--metrics", "billable_api_calls", "--start-time", "2025-05-01", "--end-time", "2025-05-31"],
    "q18": ["--metrics", "bookings", "--start-time", "2024-01-01", "--end-time", "2024-12-31"],
    "q19": ["--metrics", "win_rate", "--start-time", "2025-01-01", "--end-time", "2025-06-30"],
    "q28": ["--metrics", "new_customers", "--start-time", "2025-04-01", "--end-time", "2025-06-30"],
    "q29": ["--metrics", "logo_churn", "--start-time", "2024-01-01", "--end-time", "2024-12-31"],
}


def checksums(warehouse):
    con = duckdb.connect(warehouse, read_only=True)
    tables = con.execute("select table_schema, table_name from information_schema.tables where table_schema in ('raw', 'marts') order by 1, 2").fetchall()
    out = {}
    for schema, name in tables:
        n, h = con.execute("select count(*), md5(string_agg(cast(t as varchar), chr(10) order by cast(t as varchar))) from %s.%s t" % (schema, name)).fetchone()
        out["%s.%s" % (schema, name)] = [n, h]
    con.close()
    return out


def layer_status(layer, src, dest, warehouse):
    _, status = make_layer(layer, src, dest=dest, warehouse=warehouse)
    return status


def reference_answers(layer_dest):
    project = os.path.join(layer_dest, "project")
    db = os.path.join(layer_dest, "warehouse.duckdb")
    out = {}
    for qid, args in REFERENCE_CHECKS.items():
        p = subprocess.run([os.path.join(VENV_BIN, "python"), os.path.join(TOOLS, "mfwrap.py"), os.path.join(TOOL_BIN, "mf"), project, db, "query"] + args, capture_output=True, text=True)
        lines = [l for l in p.stdout.strip().splitlines() if l]
        try:
            out[qid] = float(lines[-1].split(",")[-1])
        except (ValueError, IndexError):
            out[qid] = None
    return out


def regrade(answers, path):
    rows = latest_rows(path)
    grid = {l: {m: 0 for m in MODELS} for l in LAYERS}
    for (m, l, q), r in rows.items():
        if grade(answers[q]["kind"], answers[q]["answer"], r.get("answer")):
            grid[l][m] += 1
    return {"sessions": len(rows), "grid": grid, "pooled": {l: sum(grid[l].values()) for l in LAYERS}}


def environment():
    def cmd(args):
        try:
            return subprocess.run(args, capture_output=True, text=True, timeout=30).stdout.strip().splitlines()[0]
        except Exception:
            return None
    models = collections.Counter()
    for f in glob.glob(os.path.join(RESULTS, "logs", "*", "*.jsonl")):
        with open(f) as fh:
            text = fh.read(4000)
        m = re.search(r'"model":"([^"]+)"', text)
        if m:
            models[m.group(1)] += 1
        elif "muse-spark" in text:
            models["muse-spark-1.3-contributor"] += 1
    lock = open(os.path.join(ROOT, "requirements.lock")).read()
    pins = {k: v for k, v in (l.split("==") for l in lock.splitlines() if "==" in l) if k in ("duckdb", "dbt-core", "dbt-duckdb", "dbt-metricflow", "metricflow")}
    return {
        "python": platform.python_version(),
        "platform": platform.platform(),
        "packages": pins,
        "claude_cli": cmd(["claude", "--version"]),
        "muse_cli": cmd(["muse", "--version"]),
        "models_in_session_logs": dict(sorted(models.items())),
        "generator_seed": 20260926,
    }


def build_fresh(tmp):
    data = os.path.join(tmp, "data")
    os.makedirs(data)
    env = dict(os.environ, RELAY_DATA_DIR=data, RELAY_GEN_TRUTH=os.path.join(tmp, "generator_truth.json"))
    p = subprocess.run([os.path.join(VENV_BIN, "python"), os.path.join(ROOT, "generator", "generate.py")], env=env, capture_output=True, text=True)
    if p.returncode != 0:
        raise SystemExit("generator failed:\n" + p.stderr[-2000:])
    wh = os.path.join(data, "warehouse.duckdb")
    env = dict(os.environ, DBT_PROFILES_DIR=DBT_SRC, RELAY_DUCKDB_PATH=wh, DBT_SEND_ANONYMOUS_USAGE_STATS="false")
    p = subprocess.run([os.path.join(VENV_BIN, "dbt"), "build", "--target-path", os.path.join(tmp, "target"), "--log-path", os.path.join(tmp, "logs")], cwd=DBT_SRC, env=env, capture_output=True, text=True)
    if p.returncode != 0:
        raise SystemExit("dbt build failed:\n" + p.stdout[-2000:])
    return wh


def close(a, b):
    if isinstance(a, str) or isinstance(b, str):
        return a == b
    if a is None or b is None:
        return a is b
    return math.isclose(a, b, rel_tol=1e-9, abs_tol=1e-9)


def record():
    tmp = tempfile.mkdtemp(prefix="slb-record-")
    answers = compute(WAREHOUSE)
    manifest = {
        "tables": checksums(WAREHOUSE),
        "answers": {k: v["answer"] for k, v in answers.items()},
        "reference_answers": reference_answers(os.path.join(ROOT, "build", "layers", "reference")),
        "layers": {m: layer_status(m, os.path.join(RESULTS, "layers", m), os.path.join(tmp, m), WAREHOUSE) for m in MODELS},
        "results": regrade(answers, os.path.join(RESULTS, "queries.jsonl")),
        "environment": environment(),
    }
    shutil.rmtree(tmp, ignore_errors=True)
    with open(MANIFEST, "w") as fh:
        json.dump(manifest, fh, indent=1, sort_keys=True)
    print("wrote", MANIFEST)
    print("pooled correct per layer:", manifest["results"]["pooled"])


def verify(keep):
    expected = json.load(open(MANIFEST))
    tmp = tempfile.mkdtemp(prefix="slb-verify-")
    checks = []

    def check(name, ok, detail=""):
        checks.append((name, ok))
        print(("PASS " if ok else "FAIL ") + name + (" " + detail if detail else ""), flush=True)

    print("regenerating data and dbt marts in", tmp, flush=True)
    wh = build_fresh(tmp)
    got = checksums(wh)
    bad = [t for t in expected["tables"] if got.get(t) != expected["tables"][t]]
    check("data: %d tables match the article's warehouse" % len(expected["tables"]), not bad and set(got) == set(expected["tables"]), ", ".join(bad[:5]))

    answers = compute(wh)
    bad = [q for q, v in expected["answers"].items() if not close(answers[q]["answer"], v)]
    check("answers: all 30 match the answer key", not bad, ", ".join(bad))
    key = json.load(open(os.path.join(HIDDEN, "answers.json")))
    bad = [q for q in key if not close(key[q]["answer"], expected["answers"][q])]
    check("answers: hidden/answers.json matches the manifest", not bad, ", ".join(bad))

    ref_dest = os.path.join(tmp, "layers", "reference")
    ref_status = layer_status("reference", os.path.join(HIDDEN, "reference_layer"), ref_dest, wh)
    check("reference layer: builds, parses and validates", all(v == 0 for v in ref_status.values()), str(ref_status))
    ref = reference_answers(ref_dest)
    bad = [q for q, v in ref.items() if not close(v, expected["answers"][q])]
    check("reference layer: %d MetricFlow answers match the key" % len(ref), not bad, ", ".join(bad))

    for m in MODELS:
        status = layer_status(m, os.path.join(RESULTS, "layers", m), os.path.join(tmp, "layers", m), wh)
        check("%s layer: validation status unchanged %s" % (m, status), status == expected["layers"][m], "expected " + str(expected["layers"][m]))

    res = regrade({q: {"kind": key[q]["kind"], "answer": expected["answers"][q]} for q in key}, os.path.join(RESULTS, "queries.jsonl"))
    check("results: %d graded sessions" % res["sessions"], res["sessions"] == expected["results"]["sessions"])
    check("results: every querier x layer score matches", res["grid"] == expected["results"]["grid"])
    pooled = ", ".join("%s %d%%" % (l, round(100 * res["pooled"][l] / 150)) for l in ["reference", "muse", "fable", "opus", "sonnet", "none", "haiku"])
    check("results: pooled accuracy " + pooled, res["pooled"] == expected["results"]["pooled"])

    if not keep:
        shutil.rmtree(tmp, ignore_errors=True)
    failed = [n for n, ok in checks if not ok]
    print("\n%d of %d checks passed" % (len(checks) - len(failed), len(checks)))
    return 1 if failed else 0


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--record", action="store_true")
    ap.add_argument("--keep", action="store_true")
    a = ap.parse_args()
    if a.record:
        record()
    else:
        sys.exit(verify(a.keep))
