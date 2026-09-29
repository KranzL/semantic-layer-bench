import csv
import sys
import threading
import time

import duckdb

MAX_ROWS = 200
TIMEOUT = 60


def connect(db):
    last = None
    for _ in range(40):
        try:
            con = duckdb.connect(db, read_only=True, config={"enable_external_access": False, "autoinstall_known_extensions": False, "autoload_known_extensions": False})
            con.execute("SET lock_configuration = true")
            return con
        except duckdb.IOException as e:
            last = e
            time.sleep(0.25)
    raise last


def fmt(v):
    if isinstance(v, float):
        return repr(v)
    return "" if v is None else str(v)


def run(db, sql, out=sys.stdout):
    con = connect(db)
    timer = threading.Timer(TIMEOUT, con.interrupt)
    timer.start()
    try:
        cur = con.execute(sql)
        if cur.description is None:
            out.write("OK\n")
            return 0
        cols = [d[0] for d in cur.description]
        rows = cur.fetchmany(MAX_ROWS + 1)
    except Exception as e:
        out.write("ERROR: %s\n" % str(e).strip())
        return 1
    finally:
        timer.cancel()
        con.close()
    w = csv.writer(out)
    w.writerow(cols)
    for r in rows[:MAX_ROWS]:
        w.writerow([fmt(v) for v in r])
    if len(rows) > MAX_ROWS:
        out.write("(truncated to %d rows)\n" % MAX_ROWS)
    return 0


if __name__ == "__main__":
    db = sys.argv[1]
    args = sys.argv[2:]
    if not args:
        sys.stdout.write('usage: ./query "SELECT ..."\n')
        sys.exit(2)
    sys.exit(run(db, " ".join(args)))
