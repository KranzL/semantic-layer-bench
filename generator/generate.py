import csv
import json
import math
import os
import random
import sys
from datetime import date, datetime, timedelta

import duckdb

SEED = 20260926
START = date(2023, 1, 1)
END = date(2025, 6, 30)
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DATA = os.environ.get("RELAY_DATA_DIR", os.path.join(ROOT, "data"))
HIDDEN = os.path.join(ROOT, "hidden")

CURRENCIES = {"USD": 2, "EUR": 2, "GBP": 2, "JPY": 0}
COUNTRIES = {
    "US": ("NA", "USD", 0.0),
    "CA": ("NA", "USD", 0.05),
    "DE": ("EMEA", "EUR", 0.19),
    "FR": ("EMEA", "EUR", 0.20),
    "GB": ("EMEA", "GBP", 0.20),
    "JP": ("APAC", "JPY", 0.10),
    "AU": ("APAC", "USD", 0.10),
    "BR": ("LATAM", "USD", 0.0),
    "MX": ("LATAM", "USD", 0.16),
}
COUNTRY_WEIGHTS = {"US": 34, "CA": 6, "DE": 11, "FR": 8, "GB": 10, "JP": 9, "AU": 7, "BR": 8, "MX": 7}
PLANS = [
    ("PLN-STARTER-M", "Starter", "Starter", "month", 2900),
    ("PLN-STARTER-Y", "Starter Annual", "Starter", "year", 29000),
    ("PLN-GROWTH-M", "Growth", "Growth", "month", 5900),
    ("PLN-GROWTH-Y", "Growth Annual", "Growth", "year", 59000),
    ("PLN-SCALE-M", "Scale", "Scale", "month", 9900),
    ("PLN-SCALE-Y", "Scale Annual", "Scale", "year", 99000),
    ("PLN-ENT-Y", "Enterprise", "Enterprise", "year", 150000),
]
PLAN_BY_ID = {p[0]: p for p in PLANS}
FAMILY_ORDER = ["Starter", "Growth", "Scale", "Enterprise"]
SEGMENT_FAMILIES = {"SMB": ["Starter", "Growth"], "MidMarket": ["Growth", "Scale"], "Enterprise": ["Scale", "Enterprise"]}
SEGMENT_SEATS = {"SMB": (1, 12), "MidMarket": (10, 60), "Enterprise": (50, 400)}
SEGMENT_CHURN = {"SMB": 0.030, "MidMarket": 0.015, "Enterprise": 0.007}
REGIONS = ["NA", "EMEA", "APAC", "LATAM"]
WORDS_A = ["North", "Blue", "Silver", "Bright", "Iron", "Cedar", "Summit", "Harbor", "Nova", "Pioneer", "Atlas", "Crescent", "Granite", "Maple", "Orbit", "Prairie", "Quartz", "Riverside", "Sterling", "Tidal", "Vertex", "Willow", "Aurora", "Beacon", "Cobalt", "Delta", "Ember", "Falcon", "Golden", "Horizon"]
WORDS_B = ["Logistics", "Health", "Analytics", "Foods", "Robotics", "Media", "Labs", "Capital", "Energy", "Retail", "Systems", "Networks", "Studios", "Freight", "Bio", "Software", "Partners", "Industries", "Mobility", "Security"]
WORDS_C = ["Inc", "LLC", "GmbH", "Ltd", "SA", "Co", "Group", "KK", "Pty"]

rng = random.Random(SEED)


def days(a, b):
    return (b - a).days


def add_months(d, n):
    m = d.month - 1 + n
    y = d.year + m // 12
    m = m % 12 + 1
    last = [31, 29 if y % 4 == 0 and (y % 100 != 0 or y % 400 == 0) else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31][m - 1]
    return date(y, m, min(d.day, last))


def month_ends():
    out = []
    d = date(START.year, START.month, 1)
    while d <= END:
        nxt = add_months(d, 1)
        out.append(nxt - timedelta(days=1))
        d = nxt
    return out


def rand_date(a, b):
    return a + timedelta(days=rng.randint(0, max(0, days(a, b))))


def rand_ts(d):
    return datetime(d.year, d.month, d.day, rng.randint(0, 23), rng.randint(0, 59), rng.randint(0, 59))


def local_price(usd_minor, currency):
    if currency == "USD":
        return usd_minor
    if currency == "EUR":
        return int(round(usd_minor * 0.93 / 100.0)) * 100
    if currency == "GBP":
        return int(round(usd_minor * 0.80 / 100.0)) * 100
    return int(round(usd_minor / 100.0 * 150))


def build_fx():
    base = {"EUR": 1.07, "GBP": 1.26, "JPY": 0.0070}
    rates = {}
    cur = dict(base)
    d = START - timedelta(days=31)
    while d <= END + timedelta(days=31):
        for c in cur:
            drift = (base[c] - cur[c]) * 0.01
            cur[c] = max(base[c] * 0.8, min(base[c] * 1.2, cur[c] * (1 + rng.gauss(0, 0.004)) + drift))
            rates[(d, c)] = round(cur[c], 6 if c != "JPY" else 8)
        rates[(d, "USD")] = 1.0
        d += timedelta(days=1)
    return rates


FX = build_fx()


def usd(amount_minor, currency, on):
    return amount_minor / (10 ** CURRENCIES[currency]) * FX[(on, currency)]


class Version:
    def __init__(self, valid_from, status, plan_id, seats, unit_price_minor, discount_pct):
        self.valid_from = valid_from
        self.valid_to = None
        self.status = status
        self.plan_id = plan_id
        self.seats = seats
        self.unit_price_minor = unit_price_minor
        self.discount_pct = discount_pct


def pick_plan(segment, interval, family=None):
    families = SEGMENT_FAMILIES[segment]
    fam = family or rng.choice(families)
    candidates = [p for p in PLANS if p[2] == fam and p[3] == interval]
    if not candidates:
        candidates = [p for p in PLANS if p[2] == fam]
    return candidates[0]


def main():
    os.makedirs(DATA, exist_ok=True)
    os.makedirs(HIDDEN, exist_ok=True)
    reps = []
    rep_id = 1
    for region in REGIONS:
        for _ in range(4 if region in ("NA", "EMEA") else 3):
            reps.append({"rep_id": "REP-%03d" % rep_id, "rep_name": "%s %s" % (rng.choice(["Ana", "Ben", "Chloe", "Dev", "Eli", "Farah", "Gus", "Hana", "Ivan", "Jade", "Kofi", "Lena", "Milo", "Nia"]), rng.choice(["Reyes", "Cole", "Singh", "Tanaka", "Moreau", "Okafor", "Berg", "Silva", "Novak", "Ito"])), "team": region + " Sales", "region": region, "hired_at": rand_date(date(2021, 1, 1), date(2023, 6, 1))})
            rep_id += 1
    reps_by_region = {r: [x for x in reps if x["region"] == r] for r in REGIONS}

    accounts = []
    n_accounts = 2000
    span = days(START, date(2025, 6, 10))
    for i in range(1, n_accounts + 1):
        u = rng.random() ** 0.8
        created = START + timedelta(days=int(u * span))
        country = rng.choices(list(COUNTRY_WEIGHTS), weights=list(COUNTRY_WEIGHTS.values()))[0]
        region, currency, _ = COUNTRIES[country]
        segment = rng.choices(["SMB", "MidMarket", "Enterprise"], weights=[62, 28, 10])[0]
        name = "%s %s %s" % (rng.choice(WORDS_A), rng.choice(WORDS_B), rng.choice(WORDS_C))
        accounts.append({"account_id": "ACC-%05d" % i, "account_name": name, "created_at": rand_ts(created), "country": country, "region": region, "segment": segment, "billing_currency": currency, "is_internal": False, "parent_account_id": None, "deleted_at": None})
    for a in rng.sample(accounts, 60):
        a["is_internal"] = True
        a["account_name"] = rng.choice(["Relay QA", "Relay Internal", "Relay Sandbox", "Relay Demo"]) + " %d" % rng.randint(1, 999)
        a["segment"] = rng.choice(["SMB", "MidMarket", "Enterprise"])
    normal = [a for a in accounts if not a["is_internal"]]
    dups = rng.sample(normal, 45)
    dup_ids = {a["account_id"] for a in dups}
    sources = rng.sample([a for a in normal if a["account_id"] not in dup_ids and a["created_at"].date() < date(2025, 3, 1)], len(dups))
    for a, src in zip(dups, sources):
        for k in ("account_name", "country", "region", "segment", "billing_currency"):
            a[k] = src[k]
        a["created_at"] = src["created_at"] + timedelta(minutes=rng.randint(5, 600))
        a["duplicate_of"] = src["account_id"]
        a["deleted_at"] = rand_ts(min(END, a["created_at"].date() + timedelta(days=rng.randint(20, 200))))
    enterprises = [a for a in normal if a["segment"] == "Enterprise" and a["deleted_at"] is None]
    for a in rng.sample([x for x in normal if x["segment"] != "Enterprise" and x["deleted_at"] is None], 150):
        parent = rng.choice(enterprises)
        if parent["created_at"] < a["created_at"]:
            a["parent_account_id"] = parent["account_id"]

    subscriptions = []
    versions = {}
    sub_seq = 1

    def new_subscription(acct, start_day, allow_trial):
        nonlocal sub_seq
        sid = "SUB-%06d" % sub_seq
        sub_seq += 1
        segment = acct["segment"]
        interval = "year" if segment == "Enterprise" or rng.random() < 0.38 else "month"
        plan = pick_plan(segment, interval)
        lo, hi = SEGMENT_SEATS[segment]
        seats = rng.randint(lo, hi)
        discount = rng.choices([0.0, 0.10, 0.15, 0.20], weights=[60, 20, 12, 8] if interval == "year" else [80, 14, 4, 2])[0]
        price = local_price(plan[4], acct["billing_currency"])
        sub = {"subscription_id": sid, "account_id": acct["account_id"], "currency": acct["billing_currency"], "created_at": rand_ts(start_day), "trial_start": None, "trial_end": None, "canceled_at": None, "ended_at": None}
        vs = []
        paid_start = start_day
        if allow_trial and rng.random() < 0.65:
            sub["trial_start"] = start_day
            sub["trial_end"] = start_day + timedelta(days=14)
            vs.append(Version(start_day, "trialing", plan[0], seats, price, discount))
            paid_start = sub["trial_end"]
            if rng.random() > 0.75 or paid_start > END:
                end_day = min(paid_start, END + timedelta(days=1))
                if paid_start <= END:
                    vs.append(Version(paid_start, "canceled", plan[0], seats, price, discount))
                    sub["canceled_at"] = rand_ts(paid_start - timedelta(days=rng.randint(0, 3)))
                    sub["ended_at"] = paid_start
                for i in range(len(vs) - 1):
                    vs[i].valid_to = vs[i + 1].valid_from
                subscriptions.append(sub)
                versions[sid] = vs
                return sid, None
        vs.append(Version(paid_start, "active", plan[0], seats, price, discount))
        subscriptions.append(sub)
        versions[sid] = vs
        return sid, paid_start

    for acct in accounts:
        if acct.get("duplicate_of"):
            continue
        start_day = acct["created_at"].date()
        sid, paid_start = new_subscription(acct, start_day, True)
        if paid_start is None:
            continue
        cursor = paid_start
        while True:
            vs = versions[sid]
            cur = vs[-1]
            plan = PLAN_BY_ID[cur.plan_id]
            interval = plan[3]
            step = 12 if interval == "year" else 1
            period_start = cursor
            period_end = add_months(period_start, step)
            if period_start > END:
                break
            month = period_start
            churned = False
            while month < period_end and month <= END:
                nxt = add_months(month, 1)
                roll = rng.random()
                change_day = month + timedelta(days=rng.randint(1, max(1, days(month, nxt) - 1)))
                if change_day <= END:
                    fam_idx = FAMILY_ORDER.index(plan[2])
                    if roll < 0.012 and fam_idx < 3 and (plan[2] != "Scale" or acct["segment"] == "Enterprise"):
                        new_plan = pick_plan(acct["segment"], interval, FAMILY_ORDER[fam_idx + 1])
                        if new_plan[2] != plan[2]:
                            vs.append(Version(change_day, cur.status, new_plan[0], cur.seats, local_price(new_plan[4], acct["billing_currency"]), cur.discount_pct))
                    elif roll < 0.016 and fam_idx > 0 and FAMILY_ORDER[fam_idx - 1] in SEGMENT_FAMILIES[acct["segment"]]:
                        new_plan = pick_plan(acct["segment"], interval, FAMILY_ORDER[fam_idx - 1])
                        if new_plan[2] != plan[2]:
                            vs.append(Version(change_day, cur.status, new_plan[0], cur.seats, local_price(new_plan[4], acct["billing_currency"]), cur.discount_pct))
                    elif roll < 0.046:
                        lo, hi = SEGMENT_SEATS[acct["segment"]]
                        delta = max(1, int(cur.seats * rng.uniform(0.05, 0.3)))
                        seats = max(1, cur.seats + (delta if rng.random() < 0.7 else -delta))
                        vs.append(Version(change_day, cur.status, cur.plan_id, seats, cur.unit_price_minor, cur.discount_pct))
                    cur = vs[-1]
                    plan = PLAN_BY_ID[cur.plan_id]
                if rng.random() < SEGMENT_CHURN[acct["segment"]] * (0.4 if acct["is_internal"] else 1.0):
                    churned = True
                month = nxt
            if churned and period_end <= END:
                sub = [s for s in subscriptions if s["subscription_id"] == sid][0]
                sub["canceled_at"] = rand_ts(period_end - timedelta(days=rng.randint(3, 25)))
                sub["ended_at"] = period_end
                vs.append(Version(period_end, "canceled", cur.plan_id, cur.seats, cur.unit_price_minor, cur.discount_pct))
                if rng.random() < 0.10:
                    restart = add_months(period_end, rng.randint(2, 6))
                    if restart <= END - timedelta(days=20):
                        for i in range(len(vs) - 1):
                            vs[i].valid_to = vs[i + 1].valid_from
                        sid, paid_start = new_subscription(acct, restart, False)
                        cursor = paid_start
                        continue
                break
            cursor = period_end
        for s_id in [s["subscription_id"] for s in subscriptions if s["account_id"] == acct["account_id"]]:
            vs = versions[s_id]
            for i in range(len(vs) - 1):
                vs[i].valid_to = vs[i + 1].valid_from

    for acct in accounts:
        if not acct.get("duplicate_of"):
            continue
        del_day = acct["deleted_at"].date()
        src_subs = [x for x in subscriptions if x["account_id"] == acct["duplicate_of"]]
        if not src_subs:
            continue
        src = src_subs[0]
        copied = []
        for v in versions[src["subscription_id"]]:
            if v.valid_from >= del_day:
                break
            nv = Version(v.valid_from, v.status, v.plan_id, v.seats, v.unit_price_minor, v.discount_pct)
            nv.valid_to = v.valid_to
            copied.append(nv)
        if not copied:
            continue
        last = copied[-1]
        dup = {"subscription_id": "SUB-%06d" % sub_seq, "account_id": acct["account_id"], "currency": src["currency"], "created_at": acct["created_at"], "trial_start": src["trial_start"], "trial_end": src["trial_end"], "canceled_at": src["canceled_at"], "ended_at": src["ended_at"]}
        sub_seq += 1
        if last.status != "canceled" and (last.valid_to is None or last.valid_to > del_day):
            last.valid_to = del_day
            copied.append(Version(del_day, "canceled", last.plan_id, last.seats, last.unit_price_minor, last.discount_pct))
            dup["canceled_at"] = acct["deleted_at"]
            dup["ended_at"] = del_day
        subscriptions.append(dup)
        versions[dup["subscription_id"]] = copied

    invoices = []
    payments = []
    credit_notes = []
    inv_seq = 1
    pay_seq = 1
    cn_seq = 1
    acct_by_id = {a["account_id"]: a for a in accounts}

    def version_on(sid, day):
        for v in versions[sid]:
            if v.valid_from <= day and (v.valid_to is None or day < v.valid_to):
                return v
        return None

    def add_invoice(acct, sid, itype, issued, p_start, p_end, subtotal, discount, currency, status):
        nonlocal inv_seq, pay_seq, cn_seq
        tax_rate = COUNTRIES[acct["country"]][2]
        tax = int(round((subtotal - discount) * tax_rate))
        inv = {"invoice_id": "INV-%07d" % inv_seq, "invoice_number": "R-%d-%06d" % (issued.year, inv_seq), "account_id": acct["account_id"], "subscription_id": sid, "invoice_type": itype, "issued_at": rand_ts(issued), "due_at": issued + timedelta(days=30), "period_start": p_start, "period_end": p_end, "currency": currency, "subtotal_minor": subtotal, "discount_minor": discount, "tax_minor": tax, "total_minor": subtotal - discount + tax, "status": status}
        inv_seq += 1
        invoices.append(inv)
        if status == "paid":
            lag = rng.randint(0, 21)
            paid_day = issued + timedelta(days=lag)
            if paid_day > END:
                inv["status"] = "open"
                return inv
            if rng.random() < 0.05:
                fail_day = issued + timedelta(days=rng.randint(0, lag)) if lag else issued
                payments.append({"payment_id": "PAY-%07d" % pay_seq, "invoice_id": inv["invoice_id"], "received_at": rand_ts(fail_day), "amount_minor": inv["total_minor"], "currency": currency, "method": rng.choice(["card", "ach", "wire"]), "status": "failed"})
                pay_seq += 1
            payments.append({"payment_id": "PAY-%07d" % pay_seq, "invoice_id": inv["invoice_id"], "received_at": rand_ts(paid_day), "amount_minor": inv["total_minor"], "currency": currency, "method": rng.choice(["card", "card", "ach", "wire"]), "status": "succeeded"})
            pay_seq += 1
            if itype == "subscription" and rng.random() < 0.025:
                cn_day = paid_day + timedelta(days=rng.randint(1, 40))
                if cn_day <= END:
                    amount = int(round((subtotal - discount) * rng.uniform(0.1, 1.0)))
                    credit_notes.append({"credit_note_id": "CN-%06d" % cn_seq, "invoice_id": inv["invoice_id"], "issued_at": rand_ts(cn_day), "amount_minor": amount, "currency": currency, "reason": rng.choice(["service_credit", "billing_error", "goodwill", "downgrade_adjustment"])})
                    cn_seq += 1
        return inv

    for sub in subscriptions:
        acct = acct_by_id[sub["account_id"]]
        if acct.get("duplicate_of"):
            continue
        vs = versions[sub["subscription_id"]]
        paid = [v for v in vs if v.status in ("active", "past_due")]
        if not paid:
            continue
        cursor = paid[0].valid_from
        end_limit = sub["ended_at"] or (END + timedelta(days=1))
        while cursor < end_limit and cursor <= END:
            v = version_on(sub["subscription_id"], cursor)
            if v is None or v.status not in ("active", "past_due"):
                break
            plan = PLAN_BY_ID[v.plan_id]
            p_end = add_months(cursor, 12 if plan[3] == "year" else 1)
            subtotal = v.seats * v.unit_price_minor
            discount = int(round(subtotal * v.discount_pct))
            roll = rng.random()
            if days(cursor, END) < 21 and rng.random() < 0.6:
                status = "open"
            elif roll < 0.005:
                status = "draft"
            elif roll < 0.020:
                status = "void"
            elif roll < 0.032 and not acct["is_internal"]:
                status = "uncollectible"
            else:
                status = "paid"
            add_invoice(acct, sub["subscription_id"], "subscription", cursor, cursor, p_end, subtotal, discount, sub["currency"], status)
            if status == "void":
                add_invoice(acct, sub["subscription_id"], "subscription", min(END, cursor + timedelta(days=rng.randint(1, 3))), cursor, p_end, subtotal, discount, sub["currency"], "paid")
            if status == "uncollectible" and sub["ended_at"] is None:
                due = cursor + timedelta(days=30)
                if due < p_end and due <= END:
                    pd = Version(due, "past_due", v.plan_id, v.seats, v.unit_price_minor, v.discount_pct)
                    later = [x for x in vs if x.valid_from > due]
                    for x in later:
                        vs.remove(x)
                    prior = version_on(sub["subscription_id"], due)
                    vs.append(pd)
                    cancel_day = p_end
                    if cancel_day <= END:
                        vs.append(Version(cancel_day, "canceled", v.plan_id, v.seats, v.unit_price_minor, v.discount_pct))
                        sub["canceled_at"] = rand_ts(cancel_day - timedelta(days=1))
                        sub["ended_at"] = cancel_day
                    vs.sort(key=lambda x: x.valid_from)
                    for i in range(len(vs)):
                        vs[i].valid_to = vs[i + 1].valid_from if i + 1 < len(vs) else None
                    end_limit = sub["ended_at"] or (END + timedelta(days=1))
            cursor = p_end

    services_pool = [a for a in accounts if a["segment"] in ("Enterprise", "MidMarket") and not a["is_internal"] and not a.get("duplicate_of")]
    for _ in range(160):
        acct = rng.choice(services_pool)
        day = rand_date(max(START, acct["created_at"].date() + timedelta(days=10)), END)
        usd_amount = rng.choice([5000, 7500, 12000, 18000, 25000, 40000]) * 100
        amount = local_price(usd_amount, acct["billing_currency"])
        status = rng.choices(["paid", "void", "draft"], weights=[94, 4, 2])[0]
        add_invoice(acct, None, "services", day, day, day, amount, 0, acct["billing_currency"], status)

    usage_path = os.path.join(DATA, "usage.csv")
    with open(usage_path, "w", newline="") as fh:
        w = csv.writer(fh)
        w.writerow(["usage_id", "account_id", "usage_date", "event_type", "quantity"])
        uid = 1
        by_acct = {}
        for sub in subscriptions:
            by_acct.setdefault(sub["account_id"], []).append(sub["subscription_id"])
        for acct in accounts:
            if acct.get("duplicate_of"):
                continue
            intensity = rng.uniform(20, 70) * (3 if acct["is_internal"] else 1)
            for sid in by_acct.get(acct["account_id"], []):
                for v in versions[sid]:
                    if v.status == "canceled":
                        continue
                    d = v.valid_from
                    stop = min(v.valid_to or (END + timedelta(days=1)), END + timedelta(days=1))
                    while d < stop:
                        if d >= START:
                            weekday = d.weekday() < 5
                            q = int(max(0, rng.gauss(v.seats * intensity * (1.0 if weekday else 0.3), v.seats * intensity * 0.2)))
                            w.writerow(["U%09d" % uid, acct["account_id"], d.isoformat(), "api_call", q])
                            uid += 1
                            w.writerow(["U%09d" % uid, acct["account_id"], d.isoformat(), "health_check", 288])
                            uid += 1
                        d += timedelta(days=1)

    opportunities = []
    opp_seq = 1

    def add_opp(acct, otype, stage, created, close, amount):
        nonlocal opp_seq
        rep = rng.choice(reps_by_region[acct["region"]])
        opportunities.append({"opportunity_id": "OPP-%06d" % opp_seq, "account_id": acct["account_id"], "rep_id": rep["rep_id"], "opportunity_type": otype, "stage": stage, "created_at": rand_ts(created), "close_date": close, "amount_usd": round(amount, 2)})
        opp_seq += 1

    def arr_usd(v, currency, on):
        plan = PLAN_BY_ID[v.plan_id]
        per = v.seats * v.unit_price_minor * (1 - v.discount_pct)
        monthly = per / 12.0 if plan[3] == "year" else per
        return usd(monthly, currency, min(on, END)) * 12

    for sub in subscriptions:
        acct = acct_by_id[sub["account_id"]]
        if acct["is_internal"] or acct.get("duplicate_of"):
            continue
        vs = versions[sub["subscription_id"]]
        first_paid = next((v for v in vs if v.status == "active"), None)
        if first_paid and first_paid.valid_from <= END:
            add_opp(acct, "new", "closed_won", first_paid.valid_from - timedelta(days=rng.randint(10, 60)), first_paid.valid_from, arr_usd(first_paid, sub["currency"], first_paid.valid_from))
        for prev, nxt in zip(vs, vs[1:]):
            if nxt.status == "active" and prev.status == "active":
                before = arr_usd(prev, sub["currency"], nxt.valid_from)
                after = arr_usd(nxt, sub["currency"], nxt.valid_from)
                if after > before * 1.02 and nxt.valid_from <= END:
                    add_opp(acct, "expansion", "closed_won", nxt.valid_from - timedelta(days=rng.randint(5, 30)), nxt.valid_from, after - before)
    for _ in range(int(len(opportunities) * 0.9)):
        acct = rng.choice([a for a in accounts if not a["is_internal"] and not a.get("duplicate_of")])
        close = rand_date(START + timedelta(days=30), END)
        amount = rng.uniform(2000, 90000) if acct["segment"] != "SMB" else rng.uniform(300, 8000)
        add_opp(acct, rng.choices(["new", "expansion"], weights=[80, 20])[0], "closed_lost", close - timedelta(days=rng.randint(10, 90)), close, amount)
    for _ in range(180):
        acct = rng.choice([a for a in accounts if not a["is_internal"] and not a.get("duplicate_of")])
        created = rand_date(date(2025, 3, 1), END)
        add_opp(acct, rng.choice(["new", "expansion"]), "open", created, rand_date(date(2025, 4, 1), date(2025, 10, 31)), rng.uniform(1000, 60000))

    con = duckdb.connect(os.path.join(DATA, "warehouse.duckdb"))
    con.execute("CREATE SCHEMA IF NOT EXISTS raw")
    for t in ["accounts", "plans", "subscriptions", "subscription_versions", "invoices", "payments", "credit_notes", "fx_rates", "currencies", "usage_events", "sales_reps", "opportunities", "fiscal_calendar"]:
        con.execute("DROP TABLE IF EXISTS raw.%s" % t)

    def load(name, rows, cols, types):
        con.execute("CREATE TABLE raw.%s (%s)" % (name, ", ".join("%s %s" % (c, t) for c, t in zip(cols, types))))
        con.executemany("INSERT INTO raw.%s VALUES (%s)" % (name, ", ".join("?" for _ in cols)), [[r[c] for c in cols] for r in rows])

    load("accounts", accounts, ["account_id", "account_name", "created_at", "country", "region", "segment", "billing_currency", "is_internal", "parent_account_id", "deleted_at"], ["VARCHAR", "VARCHAR", "TIMESTAMP", "VARCHAR", "VARCHAR", "VARCHAR", "VARCHAR", "BOOLEAN", "VARCHAR", "TIMESTAMP"])
    load("plans", [{"plan_id": p[0], "plan_name": p[1], "plan_family": p[2], "billing_interval": p[3], "list_price_usd_minor": p[4]} for p in PLANS], ["plan_id", "plan_name", "plan_family", "billing_interval", "list_price_usd_minor"], ["VARCHAR", "VARCHAR", "VARCHAR", "VARCHAR", "BIGINT"])
    load("subscriptions", subscriptions, ["subscription_id", "account_id", "currency", "created_at", "trial_start", "trial_end", "canceled_at", "ended_at"], ["VARCHAR", "VARCHAR", "VARCHAR", "TIMESTAMP", "DATE", "DATE", "TIMESTAMP", "DATE"])
    vrows = []
    vseq = 1
    for sid, vs in versions.items():
        for v in vs:
            vrows.append({"version_id": "SV-%07d" % vseq, "subscription_id": sid, "valid_from": v.valid_from, "valid_to": v.valid_to, "status": v.status, "plan_id": v.plan_id, "seats": v.seats, "unit_price_minor": v.unit_price_minor, "discount_pct": v.discount_pct})
            vseq += 1
    load("subscription_versions", vrows, ["version_id", "subscription_id", "valid_from", "valid_to", "status", "plan_id", "seats", "unit_price_minor", "discount_pct"], ["VARCHAR", "VARCHAR", "DATE", "DATE", "VARCHAR", "VARCHAR", "INTEGER", "BIGINT", "DOUBLE"])
    load("invoices", invoices, ["invoice_id", "invoice_number", "account_id", "subscription_id", "invoice_type", "issued_at", "due_at", "period_start", "period_end", "currency", "subtotal_minor", "discount_minor", "tax_minor", "total_minor", "status"], ["VARCHAR", "VARCHAR", "VARCHAR", "VARCHAR", "VARCHAR", "TIMESTAMP", "DATE", "DATE", "DATE", "VARCHAR", "BIGINT", "BIGINT", "BIGINT", "BIGINT", "VARCHAR"])
    load("payments", payments, ["payment_id", "invoice_id", "received_at", "amount_minor", "currency", "method", "status"], ["VARCHAR", "VARCHAR", "TIMESTAMP", "BIGINT", "VARCHAR", "VARCHAR", "VARCHAR"])
    load("credit_notes", credit_notes, ["credit_note_id", "invoice_id", "issued_at", "amount_minor", "currency", "reason"], ["VARCHAR", "VARCHAR", "TIMESTAMP", "BIGINT", "VARCHAR", "VARCHAR"])
    load("fx_rates", [{"rate_date": d, "currency": c, "usd_per_unit": r} for (d, c), r in sorted(FX.items())], ["rate_date", "currency", "usd_per_unit"], ["DATE", "VARCHAR", "DOUBLE"])
    load("currencies", [{"currency": c, "minor_unit_exponent": e} for c, e in CURRENCIES.items()], ["currency", "minor_unit_exponent"], ["VARCHAR", "INTEGER"])
    con.execute("CREATE TABLE raw.usage_events AS SELECT usage_id, account_id, CAST(usage_date AS DATE) AS usage_date, event_type, CAST(quantity AS BIGINT) AS quantity FROM read_csv('%s', header=true)" % usage_path)
    load("sales_reps", reps, ["rep_id", "rep_name", "team", "region", "hired_at"], ["VARCHAR", "VARCHAR", "VARCHAR", "VARCHAR", "DATE"])
    load("opportunities", opportunities, ["opportunity_id", "account_id", "rep_id", "opportunity_type", "stage", "created_at", "close_date", "amount_usd"], ["VARCHAR", "VARCHAR", "VARCHAR", "VARCHAR", "VARCHAR", "TIMESTAMP", "DATE", "DOUBLE"])
    cal = []
    d = date(2022, 2, 1)
    while d <= date(2027, 1, 31):
        fy = d.year + 1 if d.month >= 2 else d.year
        fm = (d.month - 2) % 12 + 1
        cal.append({"calendar_date": d, "fiscal_year": fy, "fiscal_quarter": (fm - 1) // 3 + 1, "fiscal_month": fm})
        d += timedelta(days=1)
    load("fiscal_calendar", cal, ["calendar_date", "fiscal_year", "fiscal_quarter", "fiscal_month"], ["DATE", "INTEGER", "INTEGER", "INTEGER"])
    con.close()
    os.remove(usage_path)

    truth = {"mrr_usd": {}, "paying_customers": {}, "billings_usd": {}}
    excluded = {a["account_id"] for a in accounts if a["is_internal"] or a["deleted_at"] is not None}
    for me in month_ends():
        total = 0.0
        paying = set()
        for sub in subscriptions:
            if sub["account_id"] in excluded:
                continue
            v = version_on(sub["subscription_id"], me)
            if v is None or v.status not in ("active", "past_due"):
                continue
            plan = PLAN_BY_ID[v.plan_id]
            local = v.seats * v.unit_price_minor * (1 - v.discount_pct) / (10 ** CURRENCIES[sub["currency"]])
            if plan[3] == "year":
                local /= 12.0
            total += local * FX[(me, sub["currency"])]
            paying.add(sub["account_id"])
        truth["mrr_usd"][me.isoformat()] = round(total, 2)
        truth["paying_customers"][me.isoformat()] = len(paying)
    for inv in invoices:
        if inv["account_id"] in excluded or inv["status"] in ("void", "draft"):
            continue
        key = inv["issued_at"].date().strftime("%Y-%m")
        truth["billings_usd"][key] = round(truth["billings_usd"].get(key, 0.0) + usd(inv["subtotal_minor"] - inv["discount_minor"], inv["currency"], inv["issued_at"].date()), 2)
    with open(os.environ.get("RELAY_GEN_TRUTH", os.path.join(HIDDEN, "generator_truth.json")), "w") as fh:
        json.dump(truth, fh, indent=1, sort_keys=True)
    print("accounts", len(accounts), "subscriptions", len(subscriptions), "versions", len(vrows), "invoices", len(invoices), "payments", len(payments), "credit_notes", len(credit_notes), "opportunities", len(opportunities))


main()
