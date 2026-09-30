# r5 notes

r5 has 4 querying models (muse, haiku, sonnet, opus), 840 sessions. The fable
querier was dropped: its per-model usage limit tripped 61 sessions in with a
week-long reset, so the remaining 149 sessions were never run. The 61 partial
fable sessions were removed for clean denominators; the raw rows are kept in
queries.fable-dropped.jsonl if a backfill is ever run. The fable-built layer
is unaffected and fully scored.
