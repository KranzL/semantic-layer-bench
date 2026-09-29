import os
import shlex
import shutil
import stat
import subprocess
import uuid

from common import DBT_SRC, LAYERS_DIR, RUN_BIN, RUNTIME, WAREHOUSE

TOOLS_SRC = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tools")
PY = os.path.join(RUN_BIN, "python")


def tools_dir():
    dest = os.path.join(RUNTIME, "tools")
    os.makedirs(dest, exist_ok=True)
    for n in os.listdir(TOOLS_SRC):
        if n.endswith(".py"):
            shutil.copy(os.path.join(TOOLS_SRC, n), os.path.join(dest, n))
    return dest


def clone(src, dst):
    if subprocess.run(["cp", "-c", src, dst], capture_output=True).returncode != 0:
        shutil.copy(src, dst)


def script(path, body):
    with open(path, "w") as fh:
        fh.write("#!/bin/sh\n" + body + "\n")
    os.chmod(path, os.stat(path).st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)


def layer_dir(layer):
    return os.path.join(LAYERS_DIR, layer)


def new_dir(kind):
    d = os.path.join(RUNTIME, kind, uuid.uuid4().hex[:12])
    os.makedirs(d)
    return d


def brokered_script(path, root, tool, t):
    script(path, 'exec %s %s %s %s "$@"' % (shlex.quote(PY), shlex.quote(os.path.join(t, "brokerclient.py")), shlex.quote(root), tool))


def query_session(layer, brokered=False):
    t = tools_dir()
    ws = new_dir("s")
    priv = os.path.join(ws, ".runtime")
    os.makedirs(priv)
    ldir = layer_dir(layer)
    commands = {}
    db = os.path.join(priv, "warehouse.duckdb")
    clone(os.path.join(ldir, "warehouse.duckdb"), db)
    script(os.path.join(ws, "query"), 'exec %s %s %s "$@"' % (shlex.quote(PY), shlex.quote(os.path.join(t, "sqlexec.py")), shlex.quote(db)))
    sem_src = os.path.join(ldir, "project", "models", "semantic")
    has_layer = os.path.isdir(sem_src) and any(n.endswith((".yml", ".yaml")) for _, _, fs in os.walk(sem_src) for n in fs)
    if has_layer:
        project = os.path.join(priv, "project")
        shutil.copytree(os.path.join(ldir, "project"), project, ignore=shutil.ignore_patterns("logs"))
        shutil.copytree(sem_src, os.path.join(ws, "semantic_layer"))
        mf_argv = [PY, os.path.join(t, "mfwrap.py"), os.path.join(RUN_BIN, "mf"), project, db]
        if brokered:
            commands["mf"] = {"argv": mf_argv, "cwd": ws, "env": {}}
            brokered_script(os.path.join(ws, "mf"), os.path.join(priv, "broker"), "mf", t)
        else:
            script(os.path.join(ws, "mf"), 'exec %s "$@"' % " ".join(shlex.quote(a) for a in mf_argv))
    return ws, priv, has_layer, commands


def build_session(brokered=False):
    t = tools_dir()
    ws = new_dir("b")
    priv = os.path.join(ws, ".runtime")
    os.makedirs(priv)
    project = os.path.join(ws, "relay_dbt")
    shutil.copytree(DBT_SRC, project, ignore=shutil.ignore_patterns("target", "logs", "dbt_packages", ".user.yml"))
    os.makedirs(os.path.join(project, "models", "semantic"), exist_ok=True)
    db = os.path.join(priv, "warehouse.duckdb")
    clone(WAREHOUSE, db)
    env = "DBT_PROFILES_DIR=%s RELAY_DUCKDB_PATH=%s DBT_SEND_ANONYMOUS_USAGE_STATS=false" % (shlex.quote(project), shlex.quote(db))
    script(os.path.join(ws, "query"), 'exec %s %s %s "$@"' % (shlex.quote(PY), shlex.quote(os.path.join(t, "sqlexec.py")), shlex.quote(db)))
    mf_argv = [PY, os.path.join(t, "mfwrap.py"), os.path.join(RUN_BIN, "mf"), project, db, "--builder"]
    commands = {}
    if brokered:
        dbt_env = {"DBT_PROFILES_DIR": project, "RELAY_DUCKDB_PATH": db, "DBT_SEND_ANONYMOUS_USAGE_STATS": "false"}
        commands["dbt"] = {"argv": [os.path.join(RUN_BIN, "dbt")], "cwd": project, "env": dbt_env}
        commands["mf"] = {"argv": mf_argv, "cwd": ws, "env": {}}
        brokered_script(os.path.join(ws, "dbt"), os.path.join(priv, "broker"), "dbt", t)
        brokered_script(os.path.join(ws, "mf"), os.path.join(priv, "broker"), "mf", t)
    else:
        script(os.path.join(ws, "dbt"), 'cd %s && %s exec %s "$@"' % (shlex.quote(project), env, shlex.quote(os.path.join(RUN_BIN, "dbt"))))
        script(os.path.join(ws, "mf"), 'exec %s "$@"' % " ".join(shlex.quote(a) for a in mf_argv))
    return ws, priv, project, commands
