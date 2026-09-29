import argparse
import json
import os
import shutil
import sys
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed

from agents import run_agent
from broker import broker
from common import LAYERS, MODELS, RESULTS, latest_rows
from prompts import ANSWER_SCHEMA, querier
from truth import load_questions
from workspace import layer_dir, query_session

LOCK = threading.Lock()


def done_keys(path):
    return set(latest_rows(path))


def one(model, layer, q, out_path, log_dir, timeout, install):
    sid = "%s-%s-%s" % (model, layer, q["id"])
    ws, priv, has_layer, commands = query_session(install, brokered=(model == "muse"))
    root = os.path.join(priv, "broker")
    if commands:
        broker().register(root, commands)
    log = os.path.join(log_dir, sid + ".jsonl")
    try:
        res = run_agent(model, querier(q["question"], has_layer), ws, priv, ANSWER_SCHEMA, False, log, timeout)
    finally:
        broker().unregister(root)
    res.update({"model": model, "layer": layer, "qid": q["id"], "workspace": ws})
    with LOCK:
        with open(out_path, "a") as fh:
            fh.write(json.dumps(res) + "\n")
    shutil.rmtree(ws, ignore_errors=True)
    return res


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models", default=",".join(MODELS))
    ap.add_argument("--layers", default=",".join(LAYERS))
    ap.add_argument("--questions", default="")
    ap.add_argument("--concurrency", type=int, default=4)
    ap.add_argument("--timeout", type=int, default=900)
    ap.add_argument("--run", default="")
    ap.add_argument("--out", default="")
    a = ap.parse_args()
    base = os.path.join(RESULTS, "runs", a.run) if a.run else RESULTS
    a.out = a.out or os.path.join(base, "queries.jsonl")
    os.makedirs(base, exist_ok=True)
    log_dir = os.path.join(base, "logs", "query")
    def install(layer):
        return layer + "-" + a.run if a.run and layer in MODELS else layer
    os.makedirs(log_dir, exist_ok=True)
    qs = load_questions()["questions"]
    if a.questions:
        wanted = set(a.questions.split(","))
        qs = [q for q in qs if q["id"] in wanted]
    models = a.models.split(",")
    layers = a.layers.split(",")
    for layer in layers:
        if not os.path.exists(os.path.join(layer_dir(install(layer)), "warehouse.duckdb")):
            sys.exit("layer %s is not built" % layer)
    done = done_keys(a.out)
    jobs = [(m, l, q) for q in qs for l in layers for m in models if (m, l, q["id"]) not in done]
    print("jobs", len(jobs), "already done", len(done), flush=True)
    limited = set()
    with ThreadPoolExecutor(max_workers=a.concurrency) as ex:
        futs = {}
        pending = list(jobs)
        def submit_next():
            while pending:
                m, l, q = pending.pop(0)
                if m in limited:
                    continue
                futs[ex.submit(one, m, l, q, a.out, log_dir, a.timeout, install(l))] = (m, l, q["id"])
                return True
            return False
        for _ in range(a.concurrency):
            submit_next()
        n = 0
        while futs:
            for f in as_completed(list(futs)):
                m, l, qid = futs.pop(f)
                n += 1
                try:
                    r = f.result()
                    if r.get("limited"):
                        limited.add(m)
                        print("LIMIT", m, "pausing this model", flush=True)
                    print(n, m, l, qid, repr(r.get("answer"))[:40], r.get("error") and r["error"][:80], r["wall_s"], flush=True)
                except Exception as e:
                    print(n, m, l, qid, "EXC", e, flush=True)
                submit_next()
                break
    if limited:
        print("models paused by usage limits:", ",".join(sorted(limited)))


if __name__ == "__main__":
    main()
