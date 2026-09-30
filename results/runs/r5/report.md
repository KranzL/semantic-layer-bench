# Results

Accuracy by querying model (rows) and semantic layer (columns). A layer column is the model that built the layer; `none` has no layer and `reference` is the layer written from the finance definitions.

| querier | none | reference | muse | haiku | sonnet | opus | fable | all |
|---|---|---|---|---|---|---|---|---|
| muse | 43% (13/30) | 100% (30/30) | 100% (30/30) | 37% (11/30) | 53% (16/30) | 60% (18/30) | 57% (17/30) | 64% (135/210) |
| haiku | 7% (2/30) | 90% (27/30) | 73% (22/30) | 13% (4/30) | 40% (12/30) | 60% (18/30) | 43% (13/30) | 47% (98/210) |
| sonnet | 57% (17/30) | 100% (30/30) | 100% (30/30) | 17% (5/30) | 53% (16/30) | 63% (19/30) | 57% (17/30) | 64% (134/210) |
| opus | 57% (17/30) | 100% (30/30) | 100% (30/30) | 30% (9/30) | 53% (16/30) | 63% (19/30) | 57% (17/30) | 66% (138/210) |
| fable | 23% (7/30) | 30% (9/30) | 30% (9/30) | 10% (3/30) | 7% (2/30) | 17% (5/30) | 10% (3/30) | 18% (38/210) |
| all | 37% (56/150) | 84% (126/150) | 81% (121/150) | 21% (32/150) | 41% (62/150) | 53% (79/150) | 45% (67/150) | - |

## By question area

| layer | billings | cash | churn | customers | mrr | refunds | revenue | sales | usage |
|---|---|---|---|---|---|---|---|---|---|
| none | 10% | 40% | 7% | 20% | 46% | 40% | 40% | 68% | 60% |
| reference | 90% | 80% | 93% | 80% | 89% | 80% | 90% | 72% | 80% |
| muse | 80% | 80% | 93% | 70% | 86% | 80% | 90% | 72% | 80% |
| haiku | 5% | 10% | 0% | 15% | 6% | 20% | 10% | 68% | 60% |
| sonnet | 90% | 80% | 0% | 0% | 17% | 80% | 80% | 72% | 0% |
| opus | 75% | 80% | 33% | 0% | 49% | 80% | 70% | 76% | 40% |
| fable | 85% | 80% | 33% | 0% | 9% | 80% | 80% | 72% | 40% |

## By trap

Accuracy on questions that exercise each trap.

| layer | annual | event_type | fiscal | fx | internal | minor_units | new_definition | open_opps | opp_type | payment_status | plan_version | recognition | rep_team | stage | status | tax | void_draft |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| none | 45% | 60% | 50% | 37% | 33% | 40% | 0% | 60% | 80% | 40% | 20% | 40% | 60% | 70% | 30% | 10% | 20% |
| reference | 88% | 80% | 80% | 90% | 88% | 90% | 80% | 70% | 80% | 80% | 60% | 90% | 60% | 70% | 87% | 90% | 90% |
| muse | 82% | 80% | 75% | 87% | 85% | 90% | 80% | 70% | 80% | 80% | 60% | 90% | 80% | 70% | 83% | 80% | 83% |
| haiku | 5% | 60% | 35% | 13% | 12% | 0% | 0% | 60% | 60% | 10% | 0% | 10% | 40% | 80% | 7% | 5% | 7% |
| sonnet | 15% | 0% | 80% | 63% | 28% | 70% | 0% | 70% | 80% | 80% | 0% | 80% | 80% | 70% | 9% | 90% | 87% |
| opus | 42% | 40% | 80% | 70% | 49% | 60% | 0% | 70% | 80% | 80% | 0% | 70% | 60% | 80% | 31% | 75% | 73% |
| fable | 8% | 40% | 80% | 53% | 33% | 40% | 0% | 70% | 80% | 80% | 0% | 80% | 80% | 70% | 11% | 85% | 83% |

## By question

Number of correct answers out of the querying models, per layer.

| id | question | none | reference | muse | haiku | sonnet | opus | fable |
|---|---|---|---|---|---|---|---|---|
| q01 | What was our MRR at the end of June 2025, in USD? | 4/5 | 5/5 | 5/5 | 0/5 | 3/5 | 5/5 | 0/5 |
| q02 | What was ARR at the end of December 2024? | 1/5 | 5/5 | 5/5 | 0/5 | 0/5 | 5/5 | 0/5 |
| q03 | How many paying customers did we have at the end of March 2025? | 1/5 | 5/5 | 4/5 | 3/5 | 0/5 | 0/5 | 0/5 |
| q04 | What was ARPA at the end of June 2025? | 4/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q05 | How many customers churned in May 2025? | 1/5 | 5/5 | 5/5 | 0/5 | 0/5 | 5/5 | 5/5 |
| q06 | What was the logo churn rate in April 2025? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q07 | What were total billings in January through March 2025? | 1/5 | 5/5 | 5/5 | 1/5 | 5/5 | 5/5 | 5/5 |
| q08 | What were total billings in fiscal year 2025? | 1/5 | 5/5 | 4/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q09 | How much revenue did we recognize in March 2025? | 3/5 | 5/5 | 5/5 | 1/5 | 4/5 | 4/5 | 4/5 |
| q10 | How much revenue did we recognize in Q3 of fiscal 2025? | 1/5 | 4/5 | 4/5 | 0/5 | 4/5 | 3/5 | 4/5 |
| q11 | How much cash did we collect in June 2025? | 2/5 | 4/5 | 4/5 | 1/5 | 4/5 | 4/5 | 4/5 |
| q12 | What was the total amount refunded to customers in 2024? | 2/5 | 4/5 | 4/5 | 1/5 | 4/5 | 4/5 | 4/5 |
| q13 | How many billable API calls did customers make in May 2025? | 3/5 | 4/5 | 4/5 | 3/5 | 0/5 | 4/5 | 4/5 |
| q14 | What was MRR from EMEA customers at the end of June 2025? | 3/5 | 4/5 | 4/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q15 | What was MRR from the Enterprise segment at the end of December 2024? | 0/5 | 4/5 | 4/5 | 0/5 | 0/5 | 2/5 | 0/5 |
| q16 | How many paying customers were on an annual plan at the end of June 2025? | 2/5 | 4/5 | 3/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q17 | What were new-business bookings in Q4 of fiscal 2025? | 4/5 | 4/5 | 4/5 | 3/5 | 4/5 | 4/5 | 4/5 |
| q18 | What were total bookings in calendar year 2024? | 3/5 | 4/5 | 4/5 | 4/5 | 4/5 | 4/5 | 4/5 |
| q19 | What was our win rate in the first half of 2025? | 3/5 | 4/5 | 3/5 | 4/5 | 3/5 | 4/5 | 3/5 |
| q20 | What was the EMEA Sales team's win rate in 2024? | 3/5 | 3/5 | 4/5 | 2/5 | 4/5 | 3/5 | 4/5 |
| q21 | How much did MRR grow between the end of June 2024 and the end of June 2025? | 1/5 | 4/5 | 4/5 | 0/5 | 0/5 | 4/5 | 0/5 |
| q22 | What were 2024 billings from customers billed in Japanese yen, in USD? | 0/5 | 4/5 | 4/5 | 0/5 | 4/5 | 1/5 | 4/5 |
| q23 | What share of June 2025 billings came from services invoices? | 0/5 | 4/5 | 3/5 | 0/5 | 4/5 | 4/5 | 3/5 |
| q24 | What was net cash, meaning cash collected minus refunds, in April through June 2025? | 2/5 | 4/5 | 4/5 | 0/5 | 4/5 | 4/5 | 4/5 |
| q25 | How many paying customers were on a Growth plan at the end of December 2024? | 1/5 | 3/5 | 3/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q26 | How many billable API calls did Enterprise-segment customers make in January through March 2025? | 3/5 | 4/5 | 4/5 | 3/5 | 0/5 | 0/5 | 0/5 |
| q27 | What was ARR from customers billed in British pounds at the end of June 2025, in USD? | 3/5 | 4/5 | 3/5 | 2/5 | 3/5 | 1/5 | 3/5 |
| q28 | How many new customers did we add in April through June 2025? | 0/5 | 4/5 | 4/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q29 | How many customers churned in calendar year 2024 in total? | 0/5 | 4/5 | 4/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q30 | Which sales rep had the highest bookings in fiscal year 2025? | 4/5 | 3/5 | 3/5 | 4/5 | 3/5 | 4/5 | 3/5 |

## Runs

1050 graded sessions, 150 ended without a structured answer.

| querier | median seconds | sessions |
|---|---|---|
| muse | 131 | 210 |
| haiku | 18 | 210 |
| sonnet | 12 | 210 |
| opus | 17 | 210 |
| fable | 1 | 210 |
