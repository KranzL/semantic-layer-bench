import glob
import json
import os
import re
import sys

from common import RESULTS

SUSPECT = re.compile(r"semantic-layer-bench|/hidden|answers\.json|questions\.yaml|spec\.md|reference_layer|generator|/Users/|\.\./|/private/tmp/relay/(?!tools|s/|b/)|build/layers")


def commands(path):
    for line in open(path):
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("payload_type") == "tool.result":
            t = ev["payload"].get("text", "")
            try:
                t = json.loads(t).get("command", "")
            except Exception:
                t = t.split("\n", 1)[0] if t.startswith("Read text file") else ""
            if t:
                yield t
        if ev.get("type") == "assistant":
            for c in ev.get("message", {}).get("content", []):
                if c.get("type") == "tool_use":
                    yield json.dumps(c.get("input"))


def main():
    flagged = 0
    files = sorted(glob.glob(os.path.join(RESULTS, "logs", "*", "*.jsonl")))
    for f in files:
        for cmd in commands(f):
            if SUSPECT.search(cmd):
                flagged += 1
                print(os.path.basename(f), "|", cmd[:300].replace("\n", " "))
    print("files", len(files), "flagged commands", flagged)


if __name__ == "__main__":
    main()
