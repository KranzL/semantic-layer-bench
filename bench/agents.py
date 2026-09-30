import json
import os
import re
import subprocess
import time
import uuid

CLAUDE_MODELS = {"haiku": "haiku", "sonnet": "sonnet", "opus": "opus", "fable": "fable"}
LIMIT_MARKERS = ("usage limit", "rate limit", "limit reached", "hit your limit", "session limit", "hit your session", "quota", "transport error", "error sending request", "reached your")


def extract_json(text):
    dec = json.JSONDecoder()
    for m in re.finditer(r"\{", text):
        try:
            obj, _ = dec.raw_decode(text[m.start():])
        except ValueError:
            continue
        if isinstance(obj, dict):
            return obj
    return None


def child_env():
    keep = ["PATH", "HOME", "USER", "LOGNAME", "SHELL", "TMPDIR", "LANG", "TERM"]
    env = {k: os.environ[k] for k in keep if k in os.environ}
    env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:" + os.path.expanduser("~/.local/bin")
    return env


def run_claude(model, prompt, ws, schema, builder, log_path, timeout):
    tools = "Bash,Read,Glob,Grep,Edit,Write" if builder else "Bash,Read,Glob,Grep"
    allowed = ["Bash(./query:*)", "Bash(./mf:*)", "Read", "Glob", "Grep"]
    if builder:
        allowed += ["Bash(./dbt:*)", "Edit", "Write"]
    cmd = ["claude", "-p", prompt, "--model", CLAUDE_MODELS[model], "--safe-mode", "--restricted", "--strict-mcp-config",
           "--tools", tools, "--allowedTools"] + allowed + ["--permission-mode", "dontAsk", "--no-session-persistence",
           "--output-format", "stream-json", "--verbose", "--json-schema", json.dumps(schema)]
    start = time.time()
    try:
        p = subprocess.run(cmd, cwd=ws, env=child_env(), capture_output=True, text=True, timeout=timeout)
        out, err, code = p.stdout, p.stderr, p.returncode
    except subprocess.TimeoutExpired as e:
        out = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        err, code = "timeout", -1
    wall = time.time() - start
    with open(log_path, "w") as fh:
        fh.write(out)
        if err:
            fh.write("\n#STDERR\n" + err)
    result = {"wall_s": round(wall, 1), "exit": code, "answer": None, "method": None, "error": None, "tool_calls": 0, "cost_usd_equiv": None}
    final = None
    for line in out.splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "assistant":
            for c in ev.get("message", {}).get("content", []):
                if c.get("type") == "tool_use":
                    result["tool_calls"] += 1
        if ev.get("type") == "result":
            final = ev
    if final is None:
        result["error"] = ("no result event: " + err[-500:]).strip()
    else:
        result["cost_usd_equiv"] = final.get("total_cost_usd")
        result["num_turns"] = final.get("num_turns")
        so = final.get("structured_output")
        if isinstance(so, dict):
            result.update({k: so.get(k) for k in schema["properties"]})
        elif final.get("is_error"):
            result["error"] = str(final.get("result"))[:500]
        else:
            so = extract_json(final.get("result") or "")
            if so is not None:
                result.update({k: so.get(k) for k in schema["properties"]})
            else:
                result["error"] = "unstructured: " + str(final.get("result"))[:500]
    text = (out[-3000:] + err[-1000:] + str(result.get("error"))).lower()
    result["limited"] = result.get("answer") is None and result.get("summary") is None and any(m in text for m in LIMIT_MARKERS)
    return result


def run_muse(prompt, ws, priv, schema, builder, log_path, timeout, max_steps):
    sid = str(uuid.uuid4())
    pf = os.path.join(priv, "prompt-%s.txt" % sid)
    sf = os.path.join(priv, "schema-%s.json" % sid)
    open(pf, "w").write(prompt)
    json.dump(schema, open(sf, "w"))
    cmd = ["muse", "exec", "--workspace", ws, "--prompt-file", pf, "--approval-mode", "never", "--json",
           "--output-schema", sf, "--max-model-steps", str(max_steps), "--session-id", sid]
    if not builder:
        cmd.append("--disable-write")
    start = time.time()
    try:
        p = subprocess.run(cmd, cwd=ws, env=child_env(), capture_output=True, text=True, timeout=timeout)
        out, err, code = p.stdout, p.stderr, p.returncode
    except subprocess.TimeoutExpired as e:
        out = e.stdout.decode() if isinstance(e.stdout, bytes) else (e.stdout or "")
        err, code = "timeout", -1
    wall = time.time() - start
    with open(log_path, "w") as fh:
        fh.write(out)
        if err:
            fh.write("\n#STDERR\n" + err)
    result = {"wall_s": round(wall, 1), "exit": code, "answer": None, "method": None, "error": None, "tool_calls": 0, "session_id": sid}
    for line in out.splitlines():
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        pt = ev.get("payload_type")
        if pt == "tool.result":
            result["tool_calls"] += 1
        if pt == "run.terminal.completed":
            pl = ev.get("payload", {})
            if pl.get("terminal") != "completed":
                result["error"] = "terminal: %s %s" % (pl.get("terminal"), pl.get("reason"))
                continue
            so = extract_json(pl.get("text") or "")
            if so is not None:
                result.update({k: so.get(k) for k in schema["properties"]})
            else:
                result["error"] = "unstructured: " + str(pl.get("text"))[:500]
    if result["error"] is None and all(result.get(k) is None for k in schema["properties"]):
        result["error"] = ("no final answer: " + err[-500:]).strip()
    text = (out[-3000:] + err[-1000:]).lower()
    result["limited"] = result.get("error") is not None and any(m in text for m in LIMIT_MARKERS)
    return result


def run_agent(model, prompt, ws, priv, schema, builder, log_path, timeout):
    if model == "muse":
        return run_muse(prompt, ws, priv, schema, builder, log_path, timeout, 200 if builder else 60)
    return run_claude(model, prompt, ws, schema, builder, log_path, timeout)
