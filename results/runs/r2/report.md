# Results

Accuracy by querying model (rows) and semantic layer (columns). A layer column is the model that built the layer; `none` has no layer and `reference` is the layer written from the finance definitions.

| querier | none | reference | muse | haiku | sonnet | opus | fable | all |
|---|---|---|---|---|---|---|---|---|
| muse | 53% (16/30) | 100% (30/30) | 100% (30/30) | 33% (10/30) | 70% (21/30) | 60% (18/30) | 60% (18/30) | 68% (143/210) |
| haiku | 10% (3/30) | 83% (25/30) | 73% (22/30) | 10% (3/30) | 57% (17/30) | 53% (16/30) | 57% (17/30) | 49% (103/210) |
| sonnet | 43% (13/30) | 97% (29/30) | 97% (29/30) | 27% (8/30) | 70% (21/30) | 60% (18/30) | 57% (17/30) | 64% (135/210) |
| opus | 57% (17/30) | 100% (30/30) | 100% (30/30) | 37% (11/30) | 70% (21/30) | 67% (20/30) | 60% (18/30) | 70% (147/210) |
| fable | 73% (22/30) | 100% (30/30) | 100% (30/30) | 30% (9/30) | 70% (21/30) | 67% (20/30) | 60% (18/30) | 71% (150/210) |
| all | 47% (71/150) | 96% (144/150) | 94% (141/150) | 27% (41/150) | 67% (101/150) | 61% (92/150) | 59% (88/150) | - |

## By question area

| layer | billings | cash | churn | customers | mrr | refunds | revenue | sales | usage |
|---|---|---|---|---|---|---|---|---|---|
| none | 15% | 60% | 33% | 25% | 43% | 20% | 50% | 92% | 80% |
| reference | 90% | 100% | 100% | 95% | 94% | 100% | 100% | 96% | 100% |
| muse | 95% | 90% | 100% | 85% | 97% | 100% | 90% | 92% | 100% |
| haiku | 10% | 10% | 7% | 25% | 3% | 0% | 0% | 92% | 80% |
| sonnet | 100% | 100% | 0% | 20% | 57% | 100% | 90% | 92% | 100% |
| opus | 80% | 100% | 33% | 0% | 51% | 100% | 100% | 92% | 50% |
| fable | 95% | 100% | 0% | 50% | 57% | 100% | 0% | 96% | 0% |

## By trap

Accuracy on questions that exercise each trap.

| layer | annual | event_type | fiscal | fx | internal | minor_units | new_definition | open_opps | opp_type | payment_status | plan_version | recognition | rep_team | stage | status | tax | void_draft |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| none | 45% | 80% | 70% | 27% | 38% | 30% | 20% | 100% | 80% | 60% | 0% | 50% | 100% | 90% | 36% | 15% | 27% |
| reference | 92% | 100% | 90% | 93% | 96% | 80% | 100% | 100% | 100% | 100% | 100% | 100% | 100% | 90% | 96% | 90% | 93% |
| muse | 95% | 100% | 90% | 97% | 94% | 90% | 100% | 80% | 100% | 90% | 80% | 90% | 80% | 100% | 94% | 95% | 93% |
| haiku | 5% | 80% | 50% | 10% | 16% | 20% | 20% | 80% | 100% | 10% | 20% | 0% | 80% | 100% | 10% | 10% | 7% |
| sonnet | 60% | 100% | 90% | 83% | 56% | 100% | 0% | 90% | 100% | 100% | 0% | 90% | 80% | 90% | 34% | 100% | 97% |
| opus | 45% | 50% | 85% | 80% | 52% | 70% | 0% | 100% | 80% | 100% | 0% | 100% | 100% | 90% | 33% | 80% | 87% |
| fable | 62% | 0% | 75% | 80% | 48% | 90% | 100% | 90% | 100% | 100% | 0% | 0% | 80% | 100% | 43% | 95% | 63% |

## By question

Number of correct answers out of the querying models, per layer.

| id | question | none | reference | muse | haiku | sonnet | opus | fable |
|---|---|---|---|---|---|---|---|---|
| q01 | What was our MRR at the end of June 2025, in USD? | 3/5 | 4/5 | 4/5 | 1/5 | 5/5 | 5/5 | 5/5 |
| q02 | What was ARR at the end of December 2024? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 5/5 | 0/5 |
| q03 | How many paying customers did we have at the end of March 2025? | 1/5 | 5/5 | 4/5 | 2/5 | 0/5 | 0/5 | 0/5 |
| q04 | What was ARPA at the end of June 2025? | 3/5 | 5/5 | 5/5 | 0/5 | 5/5 | 0/5 | 5/5 |
| q05 | How many customers churned in May 2025? | 1/5 | 5/5 | 5/5 | 0/5 | 0/5 | 5/5 | 0/5 |
| q06 | What was the logo churn rate in April 2025? | 2/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q07 | What were total billings in January through March 2025? | 0/5 | 5/5 | 5/5 | 1/5 | 5/5 | 5/5 | 5/5 |
| q08 | What were total billings in fiscal year 2025? | 2/5 | 4/5 | 4/5 | 0/5 | 5/5 | 4/5 | 5/5 |
| q09 | How much revenue did we recognize in March 2025? | 2/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 0/5 |
| q10 | How much revenue did we recognize in Q3 of fiscal 2025? | 3/5 | 5/5 | 4/5 | 0/5 | 4/5 | 5/5 | 0/5 |
| q11 | How much cash did we collect in June 2025? | 3/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q12 | What was the total amount refunded to customers in 2024? | 1/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q13 | How many billable API calls did customers make in May 2025? | 4/5 | 5/5 | 5/5 | 4/5 | 5/5 | 5/5 | 0/5 |
| q14 | What was MRR from EMEA customers at the end of June 2025? | 3/5 | 5/5 | 5/5 | 0/5 | 5/5 | 0/5 | 5/5 |
| q15 | What was MRR from the Enterprise segment at the end of December 2024? | 1/5 | 5/5 | 5/5 | 0/5 | 0/5 | 1/5 | 0/5 |
| q16 | How many paying customers were on an annual plan at the end of June 2025? | 3/5 | 4/5 | 4/5 | 1/5 | 4/5 | 0/5 | 5/5 |
| q17 | What were new-business bookings in Q4 of fiscal 2025? | 4/5 | 5/5 | 5/5 | 5/5 | 5/5 | 4/5 | 5/5 |
| q18 | What were total bookings in calendar year 2024? | 4/5 | 5/5 | 5/5 | 5/5 | 5/5 | 5/5 | 5/5 |
| q19 | What was our win rate in the first half of 2025? | 5/5 | 5/5 | 4/5 | 4/5 | 5/5 | 5/5 | 5/5 |
| q20 | What was the EMEA Sales team's win rate in 2024? | 5/5 | 5/5 | 4/5 | 4/5 | 4/5 | 5/5 | 4/5 |
| q21 | How much did MRR grow between the end of June 2024 and the end of June 2025? | 1/5 | 4/5 | 5/5 | 0/5 | 0/5 | 5/5 | 0/5 |
| q22 | What were 2024 billings from customers billed in Japanese yen, in USD? | 0/5 | 4/5 | 5/5 | 1/5 | 5/5 | 2/5 | 4/5 |
| q23 | What share of June 2025 billings came from services invoices? | 1/5 | 5/5 | 5/5 | 0/5 | 5/5 | 5/5 | 5/5 |
| q24 | What was net cash, meaning cash collected minus refunds, in April through June 2025? | 3/5 | 5/5 | 4/5 | 1/5 | 5/5 | 5/5 | 5/5 |
| q25 | How many paying customers were on a Growth plan at the end of December 2024? | 0/5 | 5/5 | 4/5 | 1/5 | 0/5 | 0/5 | 0/5 |
| q26 | How many billable API calls did Enterprise-segment customers make in January through March 2025? | 4/5 | 5/5 | 5/5 | 4/5 | 5/5 | 0/5 | 0/5 |
| q27 | What was ARR from customers billed in British pounds at the end of June 2025, in USD? | 4/5 | 5/5 | 5/5 | 0/5 | 5/5 | 2/5 | 5/5 |
| q28 | How many new customers did we add in April through June 2025? | 1/5 | 5/5 | 5/5 | 1/5 | 0/5 | 0/5 | 5/5 |
| q29 | How many customers churned in calendar year 2024 in total? | 2/5 | 5/5 | 5/5 | 1/5 | 0/5 | 0/5 | 0/5 |
| q30 | Which sales rep had the highest bookings in fiscal year 2025? | 5/5 | 4/5 | 5/5 | 5/5 | 4/5 | 4/5 | 5/5 |

## Runs

1050 graded sessions, 1 ended without a structured answer.

| querier | median seconds | sessions |
|---|---|---|
| muse | 129 | 210 |
| haiku | 23 | 210 |
| sonnet | 14 | 210 |
| opus | 19 | 210 |
| fable | 34 | 210 |
