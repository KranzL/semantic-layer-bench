# Results

Accuracy by querying model (rows) and semantic layer (columns). A layer column is the model that built the layer; `none` has no layer and `reference` is the layer written from the finance definitions.

| querier | none | reference | muse | haiku | sonnet | opus | fable | all |
|---|---|---|---|---|---|---|---|---|
| muse | 17% (5/30) | 47% (14/30) | 47% (14/30) | 3% (1/30) | 27% (8/30) | 23% (7/30) | 30% (9/30) | 28% (58/210) |
| haiku | 13% (4/30) | 83% (25/30) | 77% (23/30) | 7% (2/30) | 47% (14/30) | 47% (14/30) | 63% (19/30) | 48% (101/210) |
| sonnet | 57% (17/30) | 100% (30/30) | 100% (30/30) | 20% (6/30) | 53% (16/30) | 50% (15/30) | 63% (19/30) | 63% (133/210) |
| opus | 60% (18/30) | 100% (30/30) | 100% (30/30) | 30% (9/30) | 53% (16/30) | 53% (16/30) | 67% (20/30) | 66% (139/210) |
| fable | 70% (21/30) | 97% (29/30) | 100% (30/30) | 30% (9/30) | 53% (16/30) | 53% (16/30) | 67% (20/30) | 67% (141/210) |
| all | 43% (65/150) | 85% (128/150) | 85% (127/150) | 18% (27/150) | 47% (70/150) | 45% (68/150) | 58% (87/150) | - |

## By question area

| layer | billings | cash | churn | customers | mrr | refunds | revenue | sales | usage |
|---|---|---|---|---|---|---|---|---|---|
| none | 15% | 50% | 7% | 25% | 46% | 60% | 60% | 76% | 70% |
| reference | 85% | 90% | 87% | 80% | 89% | 100% | 90% | 76% | 90% |
| muse | 85% | 90% | 87% | 80% | 89% | 100% | 90% | 72% | 90% |
| haiku | 0% | 0% | 0% | 15% | 3% | 0% | 0% | 68% | 60% |
| sonnet | 65% | 90% | 0% | 20% | 14% | 100% | 100% | 76% | 50% |
| opus | 75% | 90% | 0% | 15% | 20% | 100% | 100% | 76% | 0% |
| fable | 90% | 90% | 0% | 35% | 51% | 100% | 100% | 80% | 0% |

## By trap

Accuracy on questions that exercise each trap.

| layer | annual | event_type | fiscal | fx | internal | minor_units | new_definition | open_opps | opp_type | payment_status | plan_version | recognition | rep_team | stage | status | tax | void_draft |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| none | 48% | 70% | 60% | 37% | 39% | 40% | 20% | 70% | 80% | 50% | 0% | 60% | 60% | 80% | 31% | 15% | 30% |
| reference | 88% | 90% | 75% | 90% | 90% | 90% | 80% | 80% | 80% | 90% | 60% | 90% | 80% | 70% | 86% | 85% | 87% |
| muse | 85% | 90% | 75% | 93% | 89% | 90% | 80% | 70% | 80% | 90% | 80% | 90% | 60% | 70% | 86% | 85% | 87% |
| haiku | 2% | 60% | 35% | 3% | 9% | 0% | 20% | 60% | 60% | 0% | 20% | 0% | 60% | 80% | 6% | 0% | 0% |
| sonnet | 12% | 50% | 85% | 50% | 40% | 50% | 0% | 70% | 80% | 90% | 80% | 100% | 60% | 80% | 13% | 65% | 77% |
| opus | 18% | 0% | 90% | 60% | 35% | 60% | 0% | 70% | 80% | 90% | 60% | 100% | 80% | 80% | 14% | 75% | 83% |
| fable | 52% | 0% | 90% | 73% | 48% | 80% | 80% | 80% | 80% | 90% | 0% | 100% | 80% | 80% | 36% | 90% | 93% |

## By question

Number of correct answers out of the querying models, per layer.

| id | question | none | reference | muse | haiku | sonnet | opus | fable |
|---|---|---|---|---|---|---|---|---|
| q01 | What was our MRR at the end of June 2025, in USD? | 4/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 4/5 |
| q02 | What was ARR at the end of December 2024? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q03 | How many paying customers did we have at the end of March 2025? | 1/5 | 5/5 | 5/5 | 1/5 | 0/5 | 0/5 | 0/5 |
| q04 | What was ARPA at the end of June 2025? | 4/5 | 5/5 | 4/5 | 0/5 | 0/5 | 0/5 | 5/5 |
| q05 | How many customers churned in May 2025? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q06 | What was the logo churn rate in April 2025? | 1/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q07 | What were total billings in January through March 2025? | 1/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q08 | What were total billings in fiscal year 2025? | 2/5 | 4/5 | 4/5 | 0/5 | 4/5 | 5/5 | 5/5 |
| q09 | How much revenue did we recognize in March 2025? | 4/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q10 | How much revenue did we recognize in Q3 of fiscal 2025? | 2/5 | 4/5 | 4/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q11 | How much cash did we collect in June 2025? | 2/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q12 | What was the total amount refunded to customers in 2024? | 3/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q13 | How many billable API calls did customers make in May 2025? | 4/5 | 5/5 | 5/5 | 3/5 | 5/5 | 0/5 | 0/5 |
| q14 | What was MRR from EMEA customers at the end of June 2025? | 3/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 5/5 |
| q15 | What was MRR from the Enterprise segment at the end of December 2024? | 2/5 | 4/5 | 4/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q16 | How many paying customers were on an annual plan at the end of June 2025? | 3/5 | 4/5 | 3/5 | 0/5 | 0/5 | 0/5 | 3/5 |
| q17 | What were new-business bookings in Q4 of fiscal 2025? | 4/5 | 4/5 | 4/5 | 3/5 | 4/5 | 4/5 | 4/5 |
| q18 | What were total bookings in calendar year 2024? | 4/5 | 4/5 | 4/5 | 4/5 | 4/5 | 4/5 | 4/5 |
| q19 | What was our win rate in the first half of 2025? | 4/5 | 4/5 | 4/5 | 3/5 | 4/5 | 3/5 | 4/5 |
| q20 | What was the EMEA Sales team's win rate in 2024? | 3/5 | 4/5 | 3/5 | 3/5 | 3/5 | 4/5 | 4/5 |
| q21 | How much did MRR grow between the end of June 2024 and the end of June 2025? | 0/5 | 4/5 | 4/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q22 | What were 2024 billings from customers billed in Japanese yen, in USD? | 0/5 | 4/5 | 4/5 | 0/5 | 0/5 | 1/5 | 4/5 |
| q23 | What share of June 2025 billings came from services invoices? | 0/5 | 4/5 | 4/5 | 0/5 | 4/5 | 4/5 | 4/5 |
| q24 | What was net cash, meaning cash collected minus refunds, in April through June 2025? | 3/5 | 4/5 | 4/5 | 0/5 | 4/5 | 4/5 | 4/5 |
| q25 | How many paying customers were on a Growth plan at the end of December 2024? | 0/5 | 3/5 | 4/5 | 1/5 | 4/5 | 3/5 | 0/5 |
| q26 | How many billable API calls did Enterprise-segment customers make in January through March 2025? | 3/5 | 4/5 | 4/5 | 3/5 | 0/5 | 0/5 | 0/5 |
| q27 | What was ARR from customers billed in British pounds at the end of June 2025, in USD? | 3/5 | 3/5 | 4/5 | 1/5 | 0/5 | 2/5 | 4/5 |
| q28 | How many new customers did we add in April through June 2025? | 1/5 | 4/5 | 4/5 | 1/5 | 0/5 | 0/5 | 4/5 |
| q29 | How many customers churned in calendar year 2024 in total? | 0/5 | 3/5 | 3/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q30 | Which sales rep had the highest bookings in fiscal year 2025? | 4/5 | 3/5 | 3/5 | 4/5 | 4/5 | 4/5 | 4/5 |

## Runs

1050 graded sessions, 114 ended without a structured answer.

| querier | median seconds | sessions |
|---|---|---|
| muse | 0 | 210 |
| haiku | 18 | 210 |
| sonnet | 10 | 210 |
| opus | 16 | 210 |
| fable | 17 | 210 |
