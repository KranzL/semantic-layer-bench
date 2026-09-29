import os
import re
import subprocess
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sqlexec import run

ALLOWED = {"query", "list"}
BLOCKED_FLAGS = {"--csv", "--saved-query-csv"}
ANSI = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]")


def clean(text):
    text = ANSI.sub("", text)
    lines = [l for l in text.replace("\r", "\n").split("\n") if not re.match(r"^\s*[⠀-⣿]", l)]
    return "\n".join(lines).strip() + "\n"


def main():
    mf, project, db = sys.argv[1], sys.argv[2], sys.argv[3]
    args = sys.argv[4:]
    allowed = set(ALLOWED)
    if args and args[0] == "--builder":
        allowed.add("validate-configs")
        args = args[1:]
    if not args or args[0] in ("-h", "--help"):
        sys.stdout.write("usage: ./mf {%s} [options]\nRun ./mf <command> --help for options.\n" % ",".join(sorted(allowed)))
        return 0
    if args[0] not in allowed:
        sys.stdout.write("ERROR: supported commands: %s\n" % ", ".join(sorted(allowed)))
        return 2
    if any(a.split("=")[0] in BLOCKED_FLAGS for a in args):
        sys.stdout.write("ERROR: writing files is not supported here\n")
        return 2
    env = dict(os.environ, DBT_PROFILES_DIR=project, RELAY_DUCKDB_PATH=db, DBT_SEND_ANONYMOUS_USAGE_STATS="false", NO_COLOR="1", TERM="dumb")
    wants_explain = "--explain" in args
    if args[0] == "query" and "--help" not in args and not wants_explain:
        p = subprocess.run([mf] + args + ["--explain"], cwd=project, env=env, capture_output=True, text=True, timeout=180)
        text = clean(p.stdout + p.stderr)
        m = re.search(r"SQL \(remove --explain[^\n]*\n(.*)", text, re.S)
        if p.returncode != 0 or not m:
            sys.stdout.write(text)
            return 1
        return run(db, m.group(1).strip())
    p = subprocess.run([mf] + args, cwd=project, env=env, capture_output=True, text=True, timeout=180)
    sys.stdout.write(clean(p.stdout + p.stderr))
    return p.returncode


if __name__ == "__main__":
    sys.exit(main())
