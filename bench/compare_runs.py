import argparse
import json
import os

from common import LAYERS, MODELS, RESULTS, latest_rows
from grade import grade
from truth import load_questions

ORDER = ["reference", "muse", "fable", "opus", "sonnet", "none", "haiku"]


def load(path):
    return latest_rows(path)


def scores(rows, answers):
    out = {}
    for (m, l, q), r in rows.items():
        out[(m, l, q)] = grade(answers[q]["kind"], answers[q]["answer"], r.get("answer"))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--a", default=os.path.join(RESULTS, "queries.jsonl"))
    ap.add_argument("--b", required=True)
    ap.add_argument("--out", default="")
    args = ap.parse_args()
    answers = json.load(open(os.path.join(os.path.dirname(RESULTS), "hidden", "answers.json")))
    sa, sb = scores(load(args.a), answers), scores(load(args.b), answers)
    keys = sorted(set(sa) & set(sb))
    lines = ["# Run comparison", "", "Sessions compared: %d (first run %d, second run %d)." % (len(keys), len(sa), len(sb)), ""]
    lines.append("| layer | first run | second run | change |")
    lines.append("|---|---|---|---|")
    for l in ORDER:
        a = sum(sa[k] for k in keys if k[1] == l)
        b = sum(sb[k] for k in keys if k[1] == l)
        n = sum(1 for k in keys if k[1] == l)
        if n:
            lines.append("| %s | %d/%d (%d%%) | %d/%d (%d%%) | %+d |" % (l, a, n, round(100 * a / n), b, n, round(100 * b / n), b - a))
    lines += ["", "Per querier and layer, second run minus first run (correct answers out of 30):", ""]
    lines.append("| querier | " + " | ".join(ORDER) + " |")
    lines.append("|---" * (len(ORDER) + 1) + "|")
    for m in MODELS:
        cells = []
        for l in ORDER:
            ks = [k for k in keys if k[0] == m and k[1] == l]
            if not ks:
                cells.append("-")
                continue
            cells.append("%+d" % (sum(sb[k] for k in ks) - sum(sa[k] for k in ks)))
        lines.append("| %s | %s |" % (m, " | ".join(cells)))
    same = sum(1 for k in keys if sa[k] == sb[k])
    lines += ["", "Sessions graded the same way in both runs: %d of %d (%d%%)." % (same, len(keys), round(100 * same / len(keys)) if keys else 0)]
    text = "\n".join(lines) + "\n"
    if args.out:
        open(args.out, "w").write(text)
    print(text)


if __name__ == "__main__":
    main()
