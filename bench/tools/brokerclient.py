import json
import os
import sys
import time
import uuid


def main():
    root, tool = sys.argv[1], sys.argv[2]
    args = sys.argv[3:]
    rid = uuid.uuid4().hex
    rq = os.path.join(root, "rq")
    rs = os.path.join(root, "rs")
    tmp = os.path.join(rq, rid + ".tmp")
    with open(tmp, "w") as fh:
        json.dump({"tool": tool, "args": args}, fh)
    os.rename(tmp, os.path.join(rq, rid + ".json"))
    target = os.path.join(rs, rid + ".json")
    deadline = time.time() + 900
    while time.time() < deadline:
        if os.path.exists(target):
            with open(target) as fh:
                res = json.load(fh)
            os.remove(target)
            sys.stdout.write(res["output"])
            return res["code"]
        time.sleep(0.2)
    sys.stdout.write("ERROR: timed out\n")
    return 1


if __name__ == "__main__":
    sys.exit(main())
