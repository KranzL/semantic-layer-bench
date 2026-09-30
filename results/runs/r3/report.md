# Results

Accuracy by querying model (rows) and semantic layer (columns). A layer column is the model that built the layer; `none` has no layer and `reference` is the layer written from the finance definitions.

| querier | none | reference | muse | haiku | sonnet | opus | fable | all |
|---|---|---|---|---|---|---|---|---|
| muse | 47% (14/30) | 100% (30/30) | 100% (30/30) | 23% (7/30) | 53% (16/30) | 50% (15/30) | 67% (20/30) | 63% (132/210) |
| haiku | 13% (4/30) | 83% (25/30) | 80% (24/30) | 7% (2/30) | 47% (14/30) | 47% (14/30) | 63% (19/30) | 49% (102/210) |
| sonnet | 57% (17/30) | 100% (30/30) | 100% (30/30) | 20% (6/30) | 53% (16/30) | 50% (15/30) | 63% (19/30) | 63% (133/210) |
| opus | 60% (18/30) | 100% (30/30) | 100% (30/30) | 30% (9/30) | 53% (16/30) | 53% (16/30) | 67% (20/30) | 66% (139/210) |
| fable | 70% (21/30) | 97% (29/30) | 100% (30/30) | 30% (9/30) | 53% (16/30) | 53% (16/30) | 67% (20/30) | 67% (141/210) |
| all | 49% (74/150) | 96% (144/150) | 96% (144/150) | 22% (33/150) | 52% (78/150) | 51% (76/150) | 65% (98/150) | - |

## By question area

| layer | billings | cash | churn | customers | mrr | refunds | revenue | sales | usage |
|---|---|---|---|---|---|---|---|---|---|
| none | 15% | 60% | 7% | 30% | 49% | 60% | 60% | 96% | 80% |
| reference | 95% | 100% | 93% | 95% | 97% | 100% | 90% | 96% | 100% |
| muse | 95% | 100% | 100% | 95% | 97% | 100% | 90% | 92% | 100% |
| haiku | 0% | 0% | 0% | 15% | 3% | 0% | 0% | 88% | 70% |
| sonnet | 70% | 100% | 0% | 25% | 14% | 100% | 100% | 96% | 50% |
| opus | 80% | 100% | 0% | 20% | 20% | 100% | 100% | 96% | 0% |
| fable | 100% | 100% | 0% | 45% | 54% | 100% | 100% | 100% | 0% |

## By trap

Accuracy on questions that exercise each trap.

| layer | annual | event_type | fiscal | fx | internal | minor_units | new_definition | open_opps | opp_type | payment_status | plan_version | recognition | rep_team | stage | status | tax | void_draft |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| none | 52% | 80% | 70% | 40% | 42% | 40% | 20% | 90% | 100% | 60% | 0% | 60% | 80% | 100% | 34% | 15% | 30% |
| reference | 98% | 100% | 85% | 97% | 97% | 100% | 100% | 100% | 100% | 100% | 80% | 90% | 100% | 90% | 96% | 95% | 93% |
| muse | 95% | 100% | 85% | 100% | 97% | 100% | 100% | 90% | 100% | 100% | 100% | 90% | 80% | 90% | 97% | 95% | 93% |
| haiku | 2% | 70% | 45% | 3% | 10% | 0% | 20% | 80% | 80% | 0% | 20% | 0% | 80% | 100% | 6% | 0% | 0% |
| sonnet | 12% | 50% | 95% | 50% | 42% | 50% | 0% | 90% | 100% | 100% | 100% | 100% | 80% | 100% | 14% | 70% | 80% |
| opus | 18% | 0% | 100% | 60% | 37% | 60% | 0% | 90% | 100% | 100% | 80% | 100% | 100% | 100% | 16% | 80% | 87% |
| fable | 58% | 0% | 100% | 80% | 50% | 90% | 100% | 100% | 100% | 100% | 0% | 100% | 100% | 100% | 40% | 100% | 100% |

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
| q15 | What was MRR from the Enterprise segment at the end of December 2024? | 2/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q16 | How many paying customers were on an annual plan at the end of June 2025? | 4/5 | 5/5 | 4/5 | 0/5 | 0/5 | 0/5 | 4/5 |
| q17 | What were new-business bookings in Q4 of fiscal 2025? | 5/5 | 5/5 | 5/5 | 4/5 | 5/5 | 5/5 | 5/5 |
| q18 | What were total bookings in calendar year 2024? | 5/5 | 5/5 | 5/5 | 5/5 | 5/5 | 5/5 | 5/5 |
| q19 | What was our win rate in the first half of 2025? | 5/5 | 5/5 | 5/5 | 4/5 | 5/5 | 4/5 | 5/5 |
| q20 | What was the EMEA Sales team's win rate in 2024? | 4/5 | 5/5 | 4/5 | 4/5 | 4/5 | 5/5 | 5/5 |
| q21 | How much did MRR grow between the end of June 2024 and the end of June 2025? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q22 | What were 2024 billings from customers billed in Japanese yen, in USD? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 1/5 | 5/5 |
| q23 | What share of June 2025 billings came from services invoices? | 0/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q24 | What was net cash, meaning cash collected minus refunds, in April through June 2025? | 4/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q25 | How many paying customers were on a Growth plan at the end of December 2024? | 0/5 | 4/5 | 5/5 | 1/5 | 5/5 | 4/5 | 0/5 |
| q26 | How many billable API calls did Enterprise-segment customers make in January through March 2025? | 4/5 | 5/5 | 5/5 | 4/5 | 0/5 | 0/5 | 0/5 |
| q27 | What was ARR from customers billed in British pounds at the end of June 2025, in USD? | 4/5 | 4/5 | 5/5 | 1/5 | 0/5 | 2/5 | 5/5 |
| q28 | How many new customers did we add in April through June 2025? | 1/5 | 5/5 | 5/5 | 1/5 | 0/5 | 0/5 | 5/5 |
| q29 | How many customers churned in calendar year 2024 in total? | 0/5 | 4/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q30 | Which sales rep had the highest bookings in fiscal year 2025? | 5/5 | 4/5 | 4/5 | 5/5 | 5/5 | 5/5 | 5/5 |

## Runs

1050 graded sessions, 0 ended without a structured answer.

| querier | median seconds | sessions |
|---|---|---|
| muse | 135 | 210 |
| haiku | 18 | 210 |
| sonnet | 10 | 210 |
| opus | 16 | 210 |
| fable | 17 | 210 |
