import argparse
import json
import os
import shutil

from agents import run_agent
from broker import broker
from common import MODELS, RESULTS
from make_layer import make_layer
from prompts import BUILD_SCHEMA, BUILDER
from workspace import build_session


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--models", default=",".join(MODELS))
    ap.add_argument("--timeout", type=int, default=5400)
    ap.add_argument("--run", default="")
    a = ap.parse_args()
    base = os.path.join(RESULTS, "runs", a.run) if a.run else RESULTS
    log_dir = os.path.join(base, "logs", "build")
    os.makedirs(log_dir, exist_ok=True)
    for model in a.models.split(","):
        ws, priv, project, commands = build_session(brokered=(model == "muse"))
        root = os.path.join(priv, "broker")
        if commands:
            broker().register(root, commands)
        try:
            res = run_agent(model, BUILDER, ws, priv, BUILD_SCHEMA, True, os.path.join(log_dir, model + ".jsonl"), a.timeout)
        finally:
            broker().unregister(root)
        dest = os.path.join(base, "layers", model)
        if os.path.exists(dest):
            shutil.rmtree(dest)
        shutil.copytree(os.path.join(project, "models", "semantic"), dest)
        path, status = make_layer(model + "-" + a.run if a.run else model, dest)
        res.update({"model": model, "workspace": ws, "layer_status": status, "files": sorted(os.listdir(dest))})
        with open(os.path.join(base, "builds.jsonl"), "a") as fh:
            fh.write(json.dumps(res) + "\n")
        print(model, res.get("error"), status, res["files"], res["wall_s"], flush=True)


if __name__ == "__main__":
    main()
