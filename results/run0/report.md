# Results

Accuracy by querying model (rows) and semantic layer (columns). A layer column is the model that built the layer; `none` has no layer and `reference` is the layer written from the finance definitions.

| querier | none | reference | muse | haiku | sonnet | opus | fable | all |
|---|---|---|---|---|---|---|---|---|
| muse | 50% (2/4) | 100% (5/5) | 100% (13/13) | 0% (0/4) | 0% (0/4) | 0% (0/4) | 0% (0/3) | 54% (20/37) |
| haiku | 20% (1/5) | 100% (5/5) | 71% (10/14) | 0% (0/5) | 0% (0/4) | 0% (0/4) | 0% (0/4) | 39% (16/41) |
| sonnet | 20% (1/5) | 100% (5/5) | 100% (14/14) | 0% (0/4) | 0% (0/4) | 0% (0/4) | 0% (0/4) | 50% (20/40) |
| opus | 60% (3/5) | 100% (5/5) | 100% (14/14) | 0% (0/4) | 0% (0/4) | 0% (0/4) | 0% (0/4) | 55% (22/40) |
| fable | 60% (3/5) | 100% (5/5) | 100% (14/14) | 0% (0/4) | 0% (0/4) | 0% (0/4) | 0% (0/4) | 55% (22/40) |
| all | 42% (10/24) | 100% (25/25) | 94% (65/69) | 0% (0/21) | 0% (0/20) | 0% (0/20) | 0% (0/19) | - |

## By question area

| layer | billings | cash | churn | customers | mrr | refunds | revenue | sales | usage |
|---|---|---|---|---|---|---|---|---|---|
| none | - | - | 50% | 20% | 47% | - | - | - | - |
| reference | - | - | 100% | 100% | 100% | - | - | - | - |
| muse | 90% | 100% | 100% | 100% | 89% | 100% | 90% | - | 100% |
| haiku | - | - | 0% | 0% | 0% | - | - | - | - |
| sonnet | - | - | - | 0% | 0% | - | - | - | - |
| opus | - | - | - | 0% | 0% | - | - | - | - |
| fable | - | - | - | 0% | 0% | - | - | - | - |

## By trap

Accuracy on questions that exercise each trap.

| layer | annual | event_type | fiscal | fx | internal | minor_units | new_definition | open_opps | opp_type | payment_status | plan_version | recognition | rep_team | stage | status | tax | void_draft |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| none | 47% | - | - | 40% | 42% | 40% | - | - | - | - | - | - | - | - | 42% | - | - |
| reference | 100% | - | - | 100% | 100% | 100% | - | - | - | - | - | - | - | - | 100% | - | - |
| muse | 89% | 100% | 80% | 90% | 95% | 80% | - | - | - | 100% | - | 90% | - | - | 94% | 90% | 90% |
| haiku | 0% | - | - | 0% | 0% | 0% | - | - | - | - | - | - | - | - | 0% | - | - |
| sonnet | 0% | - | - | 0% | 0% | 0% | - | - | - | - | - | - | - | - | 0% | - | - |
| opus | 0% | - | - | 0% | 0% | 0% | - | - | - | - | - | - | - | - | 0% | - | - |
| fable | 0% | - | - | 0% | 0% | 0% | - | - | - | - | - | - | - | - | 0% | - | - |

## By question

Number of correct answers out of the querying models, per layer.

| id | question | none | reference | muse | haiku | sonnet | opus | fable |
|---|---|---|---|---|---|---|---|---|
| q01 | What was our MRR at the end of June 2025, in USD? | 2/5 | 5/5 | 4/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q02 | What was ARR at the end of December 2024? | 2/5 | 5/5 | 4/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q03 | How many paying customers did we have at the end of March 2025? | 1/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q04 | What was ARPA at the end of June 2025? | 3/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/4 |
| q05 | How many customers churned in May 2025? | 2/4 | 5/5 | 5/5 | 0/1 | - | - | - |
| q06 | What was the logo churn rate in April 2025? | - | - | 5/5 | - | - | - | - |
| q07 | What were total billings in January through March 2025? | - | - | 5/5 | - | - | - | - |
| q08 | What were total billings in fiscal year 2025? | - | - | 4/5 | - | - | - | - |
| q09 | How much revenue did we recognize in March 2025? | - | - | 5/5 | - | - | - | - |
| q10 | How much revenue did we recognize in Q3 of fiscal 2025? | - | - | 4/5 | - | - | - | - |
| q11 | How much cash did we collect in June 2025? | - | - | 5/5 | - | - | - | - |
| q12 | What was the total amount refunded to customers in 2024? | - | - | 5/5 | - | - | - | - |
| q13 | How many billable API calls did customers make in May 2025? | - | - | 5/5 | - | - | - | - |
| q14 | What was MRR from EMEA customers at the end of June 2025? | - | - | 4/4 | - | - | - | - |
| q15 | What was MRR from the Enterprise segment at the end of December 2024? | - | - | - | - | - | - | - |
| q16 | How many paying customers were on an annual plan at the end of June 2025? | - | - | - | - | - | - | - |
| q17 | What were new-business bookings in Q4 of fiscal 2025? | - | - | - | - | - | - | - |
| q18 | What were total bookings in calendar year 2024? | - | - | - | - | - | - | - |
| q19 | What was our win rate in the first half of 2025? | - | - | - | - | - | - | - |
| q20 | What was the EMEA Sales team's win rate in 2024? | - | - | - | - | - | - | - |
| q21 | How much did MRR grow between the end of June 2024 and the end of June 2025? | - | - | - | - | - | - | - |
| q22 | What were 2024 billings from customers billed in Japanese yen, in USD? | - | - | - | - | - | - | - |
| q23 | What share of June 2025 billings came from services invoices? | - | - | - | - | - | - | - |
| q24 | What was net cash, meaning cash collected minus refunds, in April through June 2025? | - | - | - | - | - | - | - |
| q25 | How many paying customers were on a Growth plan at the end of December 2024? | - | - | - | - | - | - | - |
| q26 | How many billable API calls did Enterprise-segment customers make in January through March 2025? | - | - | - | - | - | - | - |
| q27 | What was ARR from customers billed in British pounds at the end of June 2025, in USD? | - | - | - | - | - | - | - |
| q28 | How many new customers did we add in April through June 2025? | - | - | - | - | - | - | - |
| q29 | How many customers churned in calendar year 2024 in total? | - | - | - | - | - | - | - |
| q30 | Which sales rep had the highest bookings in fiscal year 2025? | - | - | - | - | - | - | - |

## Runs

198 graded sessions, 1 ended without a structured answer.

| querier | median seconds | sessions |
|---|---|---|
| muse | 144 | 37 |
| haiku | 15 | 41 |
| sonnet | 18 | 40 |
| opus | 16 | 40 |
| fable | 27 | 40 |
