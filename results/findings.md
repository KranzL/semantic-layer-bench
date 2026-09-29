# Findings

Five models each built a dbt MetricFlow semantic layer over the same billing warehouse, working only from the data. Every model then answered 30 finance and sales questions against every layer, plus a no-layer control and a reference layer written from the finance team's definitions. 1,050 sessions, each fresh, graded against answers computed from those definitions. Full tables are in `report.md`.

## Accuracy by layer

Pooled over the five querying models, 150 sessions per layer.

| layer | correct |
|---|---|
| reference (finance definitions) | 97% (146/150) |
| built by Muse | 91% (137/150) |
| built by Fable | 67% (101/150) |
| built by Opus | 61% (92/150) |
| built by Sonnet | 41% (62/150) |
| no layer | 39% (59/150) |
| built by Haiku (no metrics defined) | 30% (45/150) |

## The layer decides the answer

When a layer defined metrics, queriers answered through it 93% to 99% of the time and rarely checked it against raw SQL. The layer's definitions carried straight through to the answers, right or wrong.

| layer | answered through the layer | correct when answered through the layer |
|---|---|---|
| reference | 147/150 | 97% |
| Muse | 145/150 | 92% |
| Fable | 148/150 | 68% |
| Opus | 139/150 | 65% |
| Sonnet | 146/150 | 42% |
| Haiku | 3/150 | 0% |

A good layer lifted the weaker queriers most. Haiku as a querier went from 10% with no layer to 90% with the reference layer and 70% with Muse's layer. A flawed layer pulled the strongest queriers down: Opus and Fable scored 57% and 60% with no layer, and 53% and 40% on Sonnet's layer.

## What each builder got wrong

Every layer that defined metrics got the arithmetic right: minor units, FX at the right date, dividing annual plans by 12, discounts, revenue recognition, bookings and win rate. The errors are all about scope: which accounts count and what counts as one customer.

- **Muse** matched the finance definitions on almost everything. Its one error: paying customers sliced by plan counted an account under the plan of a trialing or canceled subscription when the account was paying on another subscription (q25, 467 against 458). Its MRR and customer measures are not semi-additive, which the questions here did not happen to expose.
- **Fable** and **Opus** excluded internal and deleted accounts correctly, but both chose to roll subsidiaries up to their parent account as the unit of "customer" (`coalesce(parent_account_id, account_id)`). That changed every customer count, churn figure and ARPA, and any metric sliced by region, segment or currency through the customer entity took the parent's attributes. The finance definitions count each account on its own. Nothing in the data says which is right; it is a business convention, and both models made the same reasonable but different call.
- **Sonnet** excluded internal accounts only from subscription metrics. Its billings, revenue, cash, refunds and usage metrics have no account filter at all, its billings include tax (`total_minor`), and it never excludes deleted accounts, which in this data are duplicates of live accounts. 18 of 30 questions were wrong on its layer.
- **Haiku** did not produce a working layer in two attempts. After 213 and 225 tool calls it left its metric files as comments, and both times reported that it had built the layer. Its queriers fell back to raw SQL and did worse than with no layer, because the layer's descriptions described filters its measures did not apply.

## Two kinds of mistake

- **Mistakes the data could have caught:** Sonnet's missing internal filter, tax in billings and uncleaned duplicates, and Haiku's `active`-only status rule. The data shows internal accounts named "Relay QA", duplicate accounts with the same name and subscription and no invoices, and tax as a separate column.
- **Choices the data cannot settle:** the parent roll-up by Opus and Fable. A finance team would know its convention; a model building from the data alone has to guess, and here two of the strongest models guessed the same way and differently from finance.

## Caveats

- One build per model on the final dataset. Haiku failed on both its builds (the first on an earlier version of the data), so its result looks stable. The others ran once on the final data and could vary between runs.
- The reference layer, the questions and the answers were all written from the same finance definitions, so the reference layer's 97% is a ceiling rather than a fair competitor.
- The first run was stopped and discarded because the generator let deleted accounts keep billing after deletion, which contradicted the finance rule for them. It is kept in `run0/`.
- 798 Claude querier sessions hit the subscription session limit on the first pass and were rerun after the limit reset. Two sessions out of 1,050 ended without an answer and count as wrong.
- Blinding: no agent read the finance definitions, the questions, the answers or another layer. Claude sessions that tried to look outside their workspace were blocked by `--restricted`. One Muse querier read the runner script, which showed the repository path, and went no further. `audit.txt` lists every flagged command.
