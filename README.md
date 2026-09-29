# Semantic layer bench

What happens when an LLM, rather than a person who knows the business, writes the semantic layer and its definitions?

Five models each build a dbt MetricFlow semantic layer over the same B2B SaaS billing warehouse: Muse Spark 1.3 (Muse Code CLI), Claude Haiku, Sonnet, Opus and Fable (Claude Code CLI on a subscription, no API keys). Every model then answers 30 business questions against every layer, plus two controls: no layer, and a reference layer written from the finance team's definitions. That is 5 queriers x 7 layers x 30 questions = 1,050 sessions, each a fresh session.

## Blinding

The builders and queriers never see the definitions, the questions' answers or the reference layer, and their prompts do not mention an experiment.

- `hidden/` holds the finance definitions (`spec.md`), the questions with truth SQL (`questions.yaml`), the computed answers and the reference layer. Nothing under `hidden/` is copied into any agent workspace.
- Each session runs in its own directory under `/private/tmp/relay/` with a clone of the warehouse and, for layer sessions, a copy of that one layer. Directory names are random, and the scripts inside point only to `/private/tmp/relay/`, never to this repository.
- `./query` opens DuckDB read-only with external file access disabled and the configuration locked, so SQL cannot read files. `./mf` compiles a MetricFlow query and runs the SQL through the same guard.
- Claude sessions run with `--safe-mode --restricted`, which confines file tools to the workspace and loads no user instructions or memory, and Bash is limited to `./query`, `./mf` and (for builders) `./dbt`.
- Muse sessions use Muse's own sandbox, which blocks writes outside the workspace but not reads. `bench/audit.py` lists every command any agent ran that touches a path outside its workspace, so a read of this repository would show up.

## The data

`generator/generate.py` writes `data/warehouse.duckdb` from a fixed seed: 2,000 accounts from 2023-01-01 to 2025-06-30, SCD2 subscription versions with trials, plan changes, seat changes and cancellations, invoices, payments, credit notes, daily FX, daily usage and sales opportunities. The data carries the traps a real billing warehouse has, and all of them are discoverable from the data:

- internal (QA) accounts, and deleted accounts that duplicate a live account's name and subscription until the deletion date
- trialing, active, past_due and canceled subscription statuses
- annual plans that must be divided by 12 for MRR, and discounts
- amounts in minor units, with JPY at 0 decimals
- FX rates that change daily, so the conversion date matters
- tax on invoices, void and draft invoices, voided invoices reissued
- services invoices recognized at once, subscription invoices recognized over their period
- failed payment attempts
- non-billable `health_check` usage events
- open opportunities with close dates in the past
- a fiscal year starting 1 February

`relay_dbt/` is the dbt project the builders start from: staging views and mart tables, with no descriptions and no metrics.

## Run it

```
python3.13 -m venv .venv && .venv/bin/pip install -r requirements.lock
.venv/bin/python generator/generate.py
(cd relay_dbt && DBT_PROFILES_DIR=. ../.venv/bin/dbt build)
bench/setup_runtime.sh
cd bench
../.venv/bin/python truth.py
../.venv/bin/python make_layer.py none -
../.venv/bin/python make_layer.py reference ../hidden/reference_layer
../.venv/bin/python run_builds.py
../.venv/bin/python run_queries.py --concurrency 4
../.venv/bin/python report.py
../.venv/bin/python audit.py
```

`run_builds.py` saves each model's semantic layer under `results/layers/<model>/` and installs it with `make_layer.py`. `run_queries.py` is resumable: it skips any (querier, layer, question) already in `results/queries.jsonl`, and it stops scheduling a model when that model reports a usage limit, so a later rerun picks up where it stopped.

## Reproduce the published results

```
python3.13 -m venv .venv && .venv/bin/pip install -r requirements.lock
cd bench && ../.venv/bin/python reproduce.py
```

`reproduce.py` rebuilds everything deterministic from scratch in a temp directory and checks it against `results/manifest.json`, which was recorded from the run behind the article:

- the generator (seed 20260926) and `dbt build` reproduce all 25 raw and mart tables, compared by row count and an MD5 of every row
- the 30 answers recomputed from the fresh warehouse match the answer key
- the reference layer builds, validates and returns the key through MetricFlow
- each model's saved layer in `results/layers/` gets the same dbt and MetricFlow validation result (Haiku's fails)
- regrading the 1,050 recorded answers in `results/queries.jsonl` gives the same score for every querier and layer

It takes about a minute and needs no model calls. `--keep` leaves the temp directory in place.

The builds and query sessions are model output and do not replay exactly. To test whether the findings hold, rerun them into a fresh results file and compare the matrix with `report.py`. The manifest records the models the recorded sessions used (`claude-haiku-4-5-20251001`, `claude-sonnet-5`, `claude-opus-5-5`, `claude-fable-5-1`, `muse-spark-1.3-contributor`), the Claude Code and Muse CLI versions, and the pinned DuckDB, dbt and MetricFlow versions.

## Grading

Numbers pass within 0.1% of the truth, or within half a unit of the last digit given when the answer has at least three significant figures. Counts must match exactly. Rates may be given as a fraction or a percentage. The one name question passes when the answer contains the name.
