import argparse
import collections
import json
import os

from common import LAYERS, MODELS, RESULTS, latest_rows
from grade import grade
from truth import compute, load_questions


def load(path):
    return latest_rows(path)


def pct(n, d):
    return "-" if d == 0 else "%.0f%%" % (100.0 * n / d)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--inp", default=os.path.join(RESULTS, "queries.jsonl"))
    ap.add_argument("--out", default="")
    ap.add_argument("--graded", default="")
    a = ap.parse_args()
    a.out = a.out or os.path.join(os.path.dirname(a.inp), "report.md")
    a.graded = a.graded or os.path.join(os.path.dirname(a.inp), "graded.jsonl")
    truth = compute()
    qs = {q["id"]: q for q in load_questions()["questions"]}
    rows = load(a.inp)
    graded = []
    for (m, l, qid), r in rows.items():
        ok = grade(truth[qid]["kind"], truth[qid]["answer"], r.get("answer"))
        graded.append(dict(r, correct=ok))
    by = collections.defaultdict(lambda: [0, 0])
    for g in graded:
        for key in [(g["model"], g["layer"]), ("all", g["layer"]), (g["model"], "all")]:
            by[key][0] += g["correct"]
            by[key][1] += 1
    models = [m for m in MODELS if any(g["model"] == m for g in graded)]
    layers = [l for l in LAYERS if any(g["layer"] == l for g in graded)]
    out = ["# Results", "", "Accuracy by querying model (rows) and semantic layer (columns). A layer column is the model that built the layer; `none` has no layer and `reference` is the layer written from the finance definitions.", ""]
    out.append("| querier | " + " | ".join(layers) + " | all |")
    out.append("|---" * (len(layers) + 2) + "|")
    for m in models + ["all"]:
        cells = []
        for l in layers + ["all"]:
            n, d = by[(m, l)]
            cells.append("%s (%d/%d)" % (pct(n, d), n, d) if d else "-")
        out.append("| %s | %s |" % (m, " | ".join(cells)))
    out += ["", "## By question area", ""]
    areas = sorted({q["area"] for q in qs.values()})
    out.append("| layer | " + " | ".join(areas) + " |")
    out.append("|---" * (len(areas) + 1) + "|")
    for l in layers:
        cells = []
        for ar in areas:
            sel = [g for g in graded if g["layer"] == l and qs[g["qid"]]["area"] == ar]
            cells.append(pct(sum(g["correct"] for g in sel), len(sel)))
        out.append("| %s | %s |" % (l, " | ".join(cells)))
    out += ["", "## By trap", "", "Accuracy on questions that exercise each trap.", ""]
    traps = sorted({t for q in qs.values() for t in q["traps"]})
    out.append("| layer | " + " | ".join(traps) + " |")
    out.append("|---" * (len(traps) + 1) + "|")
    for l in layers:
        cells = []
        for t in traps:
            sel = [g for g in graded if g["layer"] == l and t in qs[g["qid"]]["traps"]]
            cells.append(pct(sum(g["correct"] for g in sel), len(sel)))
        out.append("| %s | %s |" % (l, " | ".join(cells)))
    out += ["", "## By question", "", "Number of correct answers out of the querying models, per layer.", ""]
    out.append("| id | question | " + " | ".join(layers) + " |")
    out.append("|---" * (len(layers) + 2) + "|")
    for qid in sorted(qs):
        cells = []
        for l in layers:
            sel = [g for g in graded if g["layer"] == l and g["qid"] == qid]
            cells.append("%d/%d" % (sum(g["correct"] for g in sel), len(sel)) if sel else "-")
        out.append("| %s | %s | %s |" % (qid, qs[qid]["question"], " | ".join(cells)))
    errs = [g for g in graded if g.get("error")]
    walls = collections.defaultdict(list)
    for g in graded:
        walls[g["model"]].append(g["wall_s"])
    out += ["", "## Runs", "", "%d graded sessions, %d ended without a structured answer." % (len(graded), len(errs)), ""]
    out.append("| querier | median seconds | sessions |")
    out.append("|---|---|---|")
    for m in models:
        w = sorted(walls[m])
        out.append("| %s | %.0f | %d |" % (m, w[len(w) // 2], len(w)))
    with open(a.out, "w") as fh:
        fh.write("\n".join(out) + "\n")
    with open(a.graded, "w") as fh:
        for g in sorted(graded, key=lambda g: (g["model"], g["layer"], g["qid"])):
            fh.write(json.dumps({k: g.get(k) for k in ["model", "layer", "qid", "answer", "correct", "method", "error", "wall_s", "tool_calls"]}) + "\n")
    print("\n".join(out[:12 + len(models)]))


if __name__ == "__main__":
    main()
