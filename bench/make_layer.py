import json
import os
import shutil
import subprocess
import sys

from common import DBT_SRC, TOOL_BIN, WAREHOUSE
from workspace import layer_dir


def run(cmd, cwd, env):
    p = subprocess.run(cmd, cwd=cwd, env=env, capture_output=True, text=True)
    return p.returncode, p.stdout + p.stderr


def make_layer(layer, semantic_src, dest=None, warehouse=WAREHOUSE):
    dest = dest or layer_dir(layer)
    if os.path.exists(dest):
        shutil.rmtree(dest)
    os.makedirs(dest)
    project = os.path.join(dest, "project")
    shutil.copytree(DBT_SRC, project, ignore=shutil.ignore_patterns("target", "logs", "dbt_packages", ".user.yml"))
    sem = os.path.join(project, "models", "semantic")
    if os.path.exists(sem):
        shutil.rmtree(sem)
    if semantic_src:
        shutil.copytree(semantic_src, sem, ignore=shutil.ignore_patterns("target", "logs", "__pycache__"))
    else:
        os.makedirs(sem)
    db = os.path.join(dest, "warehouse.duckdb")
    shutil.copy(warehouse, db)
    env = dict(os.environ, DBT_PROFILES_DIR=project, RELAY_DUCKDB_PATH=db, DBT_SEND_ANONYMOUS_USAGE_STATS="false")
    log = {}
    names = [n for _, _, fs in os.walk(sem) for n in fs]
    has_sql = any(n.endswith(".sql") for n in names)
    if has_sql:
        log["build"] = run([os.path.join(TOOL_BIN, "dbt"), "build", "--select", "path:models/semantic"], project, env)
    log["parse"] = run([os.path.join(TOOL_BIN, "dbt"), "parse"], project, env)
    has_yaml = any(n.endswith((".yml", ".yaml")) for n in names)
    if has_yaml:
        log["validate"] = run([os.path.join(TOOL_BIN, "mf"), "validate-configs", "--skip-dw"], project, env)
    status = {k: v[0] for k, v in log.items()}
    with open(os.path.join(dest, "build_log.json"), "w") as fh:
        json.dump({k: {"code": v[0], "output": v[1][-20000:]} for k, v in log.items()}, fh, indent=1)
    return dest, status


if __name__ == "__main__":
    layer = sys.argv[1]
    src = sys.argv[2] if len(sys.argv) > 2 and sys.argv[2] != "-" else None
    dest, status = make_layer(layer, src)
    print(dest, status)
