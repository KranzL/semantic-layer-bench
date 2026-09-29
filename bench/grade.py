import re

NUM = re.compile(r"-?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?")


def parse_number(text):
    s = str(text).replace(",", "").replace("$", "").replace("USD", "").strip()
    m = NUM.search(s)
    if not m:
        return None, None, False
    tok = m.group(0)
    decimals = len(tok.split(".")[1]) if "." in tok and "e" not in tok.lower() else 0
    return float(tok), decimals, "%" in s


def sig_digits(tok_value, decimals):
    digits = re.sub(r"[^0-9]", "", ("%." + str(decimals) + "f") % abs(tok_value)).lstrip("0")
    return len(digits)


def grade(kind, truth, answer):
    if answer is None:
        return False
    if kind == "text":
        return str(truth).strip().lower() in str(answer).strip().lower()
    v, decimals, pct = parse_number(answer)
    if v is None:
        return False
    candidates = [(v, decimals)]
    if kind == "rate" and (pct or v > 1):
        candidates = [(v / 100.0, decimals + 2)]
    for val, dec in candidates:
        if kind == "count":
            if abs(val - truth) < 0.5:
                return True
            continue
        half_unit = 0.5 * 10 ** (-dec)
        tol = max(0.001 * abs(truth), half_unit if sig_digits(val, dec) >= 3 else 0)
        if abs(val - truth) <= tol:
            return True
    return False
