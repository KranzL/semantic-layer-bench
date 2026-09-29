# Results

Accuracy by querying model (rows) and semantic layer (columns). A layer column is the model that built the layer; `none` has no layer and `reference` is the layer written from the finance definitions.

| querier | none | reference | muse | haiku | sonnet | opus | fable | all |
|---|---|---|---|---|---|---|---|---|
| muse | 50% (15/30) | 100% (30/30) | 100% (30/30) | 30% (9/30) | 50% (15/30) | 63% (19/30) | 60% (18/30) | 65% (136/210) |
| haiku | 10% (3/30) | 93% (28/30) | 97% (29/30) | 3% (1/30) | 40% (12/30) | 53% (16/30) | 53% (16/30) | 50% (105/210) |
| sonnet | 50% (15/30) | 100% (30/30) | 100% (30/30) | 23% (7/30) | 50% (15/30) | 63% (19/30) | 60% (18/30) | 64% (134/210) |
| opus | 57% (17/30) | 100% (30/30) | 100% (30/30) | 33% (10/30) | 53% (16/30) | 63% (19/30) | 60% (18/30) | 67% (140/210) |
| fable | 77% (23/30) | 97% (29/30) | 97% (29/30) | 27% (8/30) | 50% (15/30) | 63% (19/30) | 63% (19/30) | 68% (142/210) |
| all | 49% (73/150) | 98% (147/150) | 99% (148/150) | 23% (35/150) | 49% (73/150) | 61% (92/150) | 59% (89/150) | - |

## By question area

| layer | billings | cash | churn | customers | mrr | refunds | revenue | sales | usage |
|---|---|---|---|---|---|---|---|---|---|
| none | 20% | 40% | 20% | 30% | 46% | 40% | 70% | 92% | 80% |
| reference | 100% | 100% | 100% | 90% | 100% | 100% | 100% | 96% | 100% |
| muse | 100% | 100% | 100% | 95% | 100% | 100% | 100% | 96% | 100% |
| haiku | 0% | 0% | 0% | 20% | 17% | 0% | 0% | 72% | 70% |
| sonnet | 70% | 100% | 0% | 0% | 17% | 100% | 100% | 92% | 50% |
| opus | 100% | 100% | 0% | 50% | 14% | 80% | 100% | 96% | 90% |
| fable | 70% | 100% | 33% | 0% | 49% | 100% | 90% | 96% | 50% |

## By trap

Accuracy on questions that exercise each trap.

| layer | annual | event_type | fiscal | fx | internal | minor_units | new_definition | open_opps | opp_type | payment_status | plan_version | recognition | rep_team | stage | status | tax | void_draft |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| none | 48% | 80% | 65% | 43% | 38% | 50% | 20% | 100% | 80% | 40% | 0% | 70% | 100% | 90% | 36% | 20% | 37% |
| reference | 100% | 100% | 95% | 100% | 98% | 100% | 100% | 100% | 100% | 100% | 60% | 100% | 100% | 90% | 97% | 100% | 100% |
| muse | 100% | 100% | 95% | 100% | 99% | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 90% | 99% | 100% | 100% |
| haiku | 18% | 70% | 40% | 3% | 15% | 0% | 40% | 60% | 80% | 0% | 0% | 0% | 40% | 80% | 14% | 0% | 0% |
| sonnet | 15% | 50% | 90% | 53% | 37% | 50% | 0% | 90% | 100% | 100% | 0% | 100% | 100% | 90% | 9% | 70% | 80% |
| opus | 12% | 90% | 100% | 63% | 46% | 50% | 100% | 90% | 100% | 100% | 0% | 100% | 100% | 100% | 21% | 100% | 100% |
| fable | 42% | 50% | 85% | 77% | 52% | 70% | 0% | 100% | 100% | 100% | 0% | 90% | 100% | 90% | 31% | 70% | 77% |

## By question

Number of correct answers out of the querying models, per layer.

| id | question | none | reference | muse | haiku | sonnet | opus | fable |
|---|---|---|---|---|---|---|---|---|
| q01 | What was our MRR at the end of June 2025, in USD? | 4/5 | 5/5 | 5/5 | 0/5 | 5/5 | 0/5 | 5/5 |
| q02 | What was ARR at the end of December 2024? | 1/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 5/5 |
| q03 | How many paying customers did we have at the end of March 2025? | 2/5 | 5/5 | 4/5 | 1/5 | 0/5 | 5/5 | 0/5 |
| q04 | What was ARPA at the end of June 2025? | 4/5 | 5/5 | 5/5 | 2/5 | 0/5 | 0/5 | 0/5 |
| q05 | How many customers churned in May 2025? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 5/5 |
| q06 | What was the logo churn rate in April 2025? | 1/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q07 | What were total billings in January through March 2025? | 1/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q08 | What were total billings in fiscal year 2025? | 1/5 | 5/5 | 5/5 | 0/5 | 4/5 | 5/5 | 4/5 |
| q09 | How much revenue did we recognize in March 2025? | 3/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q10 | How much revenue did we recognize in Q3 of fiscal 2025? | 4/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 4/5 |
| q11 | How much cash did we collect in June 2025? | 3/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q12 | What was the total amount refunded to customers in 2024? | 2/5 | 5/5 | 5/5 | 0/5 | 5/5 | 4/5 | 5/5 |
| q13 | How many billable API calls did customers make in May 2025? | 4/5 | 5/5 | 5/5 | 4/5 | 5/5 | 4/5 | 5/5 |
| q14 | What was MRR from EMEA customers at the end of June 2025? | 3/5 | 5/5 | 5/5 | 2/5 | 0/5 | 0/5 | 0/5 |
| q15 | What was MRR from the Enterprise segment at the end of December 2024? | 0/5 | 5/5 | 5/5 | 1/5 | 0/5 | 0/5 | 1/5 |
| q16 | How many paying customers were on an annual plan at the end of June 2025? | 3/5 | 5/5 | 5/5 | 1/5 | 0/5 | 0/5 | 0/5 |
| q17 | What were new-business bookings in Q4 of fiscal 2025? | 4/5 | 5/5 | 5/5 | 4/5 | 5/5 | 5/5 | 5/5 |
| q18 | What were total bookings in calendar year 2024? | 5/5 | 5/5 | 5/5 | 4/5 | 5/5 | 5/5 | 5/5 |
| q19 | What was our win rate in the first half of 2025? | 5/5 | 5/5 | 5/5 | 4/5 | 4/5 | 4/5 | 5/5 |
| q20 | What was the EMEA Sales team's win rate in 2024? | 5/5 | 5/5 | 5/5 | 2/5 | 5/5 | 5/5 | 5/5 |
| q21 | How much did MRR grow between the end of June 2024 and the end of June 2025? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 5/5 |
| q22 | What were 2024 billings from customers billed in Japanese yen, in USD? | 1/5 | 5/5 | 5/5 | 0/5 | 0/5 | 5/5 | 2/5 |
| q23 | What share of June 2025 billings came from services invoices? | 1/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 3/5 |
| q24 | What was net cash, meaning cash collected minus refunds, in April through June 2025? | 1/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q25 | How many paying customers were on a Growth plan at the end of December 2024? | 0/5 | 3/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q26 | How many billable API calls did Enterprise-segment customers make in January through March 2025? | 4/5 | 5/5 | 5/5 | 3/5 | 0/5 | 5/5 | 0/5 |
| q27 | What was ARR from customers billed in British pounds at the end of June 2025, in USD? | 4/5 | 5/5 | 5/5 | 1/5 | 1/5 | 5/5 | 1/5 |
| q28 | How many new customers did we add in April through June 2025? | 1/5 | 5/5 | 5/5 | 2/5 | 0/5 | 5/5 | 0/5 |
| q29 | How many customers churned in calendar year 2024 in total? | 2/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q30 | Which sales rep had the highest bookings in fiscal year 2025? | 4/5 | 4/5 | 4/5 | 4/5 | 4/5 | 5/5 | 4/5 |

## Runs

1050 graded sessions, 3 ended without a structured answer.

| querier | median seconds | sessions |
|---|---|---|
| muse | 119 | 210 |
| haiku | 19 | 210 |
| sonnet | 11 | 210 |
| opus | 16 | 210 |
| fable | 19 | 210 |
