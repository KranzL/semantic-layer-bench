import glob
import json
import os
import subprocess
import threading
from concurrent.futures import ThreadPoolExecutor

from common import RUN_BIN


class Broker:
    def __init__(self, workers=4):
        self.sessions = {}
        self.lock = threading.Lock()
        self.pool = ThreadPoolExecutor(max_workers=workers)
        self.inflight = set()
        self.stop = threading.Event()
        self.thread = threading.Thread(target=self.loop, daemon=True)
        self.thread.start()

    def register(self, root, commands):
        os.makedirs(os.path.join(root, "rq"), exist_ok=True)
        os.makedirs(os.path.join(root, "rs"), exist_ok=True)
        with self.lock:
            self.sessions[root] = commands

    def unregister(self, root):
        with self.lock:
            self.sessions.pop(root, None)

    def loop(self):
        while not self.stop.wait(0.2):
            with self.lock:
                roots = dict(self.sessions)
            for root, commands in roots.items():
                for req in glob.glob(os.path.join(root, "rq", "*.json")):
                    if req in self.inflight:
                        continue
                    self.inflight.add(req)
                    self.pool.submit(self.handle, root, commands, req)

    def handle(self, root, commands, req):
        rid = os.path.basename(req)
        try:
            with open(req) as fh:
                r = json.load(fh)
            os.remove(req)
            base = commands.get(r.get("tool"))
            args = [str(a) for a in r.get("args", [])]
            if base is None:
                code, output = 2, "ERROR: unknown command\n"
            else:
                p = subprocess.run(base["argv"] + args, cwd=base["cwd"], env=dict(os.environ, **base["env"]), capture_output=True, text=True, timeout=600)
                code, output = p.returncode, p.stdout + p.stderr
        except subprocess.TimeoutExpired:
            code, output = 1, "ERROR: timed out\n"
        except Exception as e:
            code, output = 1, "ERROR: %s\n" % e
        tmp = os.path.join(root, "rs", rid + ".tmp")
        with open(tmp, "w") as fh:
            json.dump({"code": code, "output": output}, fh)
        os.rename(tmp, os.path.join(root, "rs", rid))
        self.inflight.discard(req)


BROKER = None


def broker():
    global BROKER
    if BROKER is None:
        BROKER = Broker()
    return BROKER
