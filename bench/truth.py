import json
import os

import duckdb
import yaml

from common import HIDDEN, WAREHOUSE


def load_questions():
    with open(os.path.join(HIDDEN, "questions.yaml")) as fh:
        return yaml.safe_load(fh)


def compute(warehouse=WAREHOUSE):
    spec = load_questions()
    con = duckdb.connect(warehouse, read_only=True)
    for stmt in spec["preamble"].split(";"):
        if stmt.strip():
            con.execute(stmt)
    out = {}
    for q in spec["questions"]:
        v = con.execute(q["sql"]).fetchone()[0]
        out[q["id"]] = {"question": q["question"], "kind": q["kind"], "answer": v if q["kind"] == "text" else float(v)}
    return out


if __name__ == "__main__":
    ans = compute()
    with open(os.path.join(HIDDEN, "answers.json"), "w") as fh:
        json.dump(ans, fh, indent=1)
    for k, v in ans.items():
        print(k, v["answer"], "|", v["question"])
