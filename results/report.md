# Results

Accuracy by querying model (rows) and semantic layer (columns). A layer column is the model that built the layer; `none` has no layer and `reference` is the layer written from the finance definitions.

| querier | none | reference | muse | haiku | sonnet | opus | fable | all |
|---|---|---|---|---|---|---|---|---|
| muse | 40% (12/30) | 100% (30/30) | 100% (30/30) | 43% (13/30) | 47% (14/30) | 60% (18/30) | 63% (19/30) | 65% (136/210) |
| haiku | 10% (3/30) | 90% (27/30) | 70% (21/30) | 10% (3/30) | 27% (8/30) | 57% (17/30) | 60% (18/30) | 46% (97/210) |
| sonnet | 30% (9/30) | 97% (29/30) | 93% (28/30) | 17% (5/30) | 40% (12/30) | 63% (19/30) | 73% (22/30) | 59% (124/210) |
| opus | 57% (17/30) | 100% (30/30) | 97% (29/30) | 40% (12/30) | 53% (16/30) | 60% (18/30) | 70% (21/30) | 68% (143/210) |
| fable | 60% (18/30) | 100% (30/30) | 97% (29/30) | 40% (12/30) | 40% (12/30) | 67% (20/30) | 70% (21/30) | 68% (142/210) |
| all | 39% (59/150) | 97% (146/150) | 91% (137/150) | 30% (45/150) | 41% (62/150) | 61% (92/150) | 67% (101/150) | - |

## By question area

| layer | billings | cash | churn | customers | mrr | refunds | revenue | sales | usage |
|---|---|---|---|---|---|---|---|---|---|
| none | 5% | 30% | 7% | 25% | 31% | 40% | 50% | 92% | 80% |
| reference | 95% | 100% | 100% | 95% | 97% | 100% | 100% | 96% | 100% |
| muse | 95% | 100% | 100% | 65% | 97% | 100% | 90% | 88% | 100% |
| haiku | 0% | 50% | 7% | 15% | 20% | 40% | 0% | 80% | 70% |
| sonnet | 0% | 20% | 0% | 50% | 54% | 0% | 30% | 92% | 50% |
| opus | 80% | 100% | 33% | 0% | 49% | 100% | 100% | 96% | 50% |
| fable | 85% | 100% | 33% | 0% | 71% | 100% | 100% | 92% | 60% |

## By trap

Accuracy on questions that exercise each trap.

| layer | annual | event_type | fiscal | fx | internal | minor_units | new_definition | open_opps | opp_type | payment_status | plan_version | recognition | rep_team | stage | status | tax | void_draft |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| none | 30% | 80% | 65% | 23% | 29% | 20% | 40% | 90% | 80% | 30% | 20% | 50% | 80% | 100% | 24% | 5% | 20% |
| reference | 98% | 100% | 90% | 97% | 98% | 100% | 100% | 100% | 100% | 100% | 80% | 100% | 100% | 90% | 97% | 95% | 97% |
| muse | 92% | 100% | 85% | 93% | 92% | 90% | 100% | 90% | 80% | 100% | 20% | 90% | 100% | 90% | 89% | 95% | 93% |
| haiku | 18% | 70% | 45% | 13% | 22% | 0% | 0% | 90% | 80% | 50% | 20% | 0% | 80% | 70% | 16% | 0% | 0% |
| sonnet | 60% | 50% | 50% | 30% | 30% | 40% | 100% | 100% | 80% | 20% | 0% | 30% | 100% | 90% | 41% | 0% | 10% |
| opus | 42% | 50% | 100% | 77% | 52% | 60% | 0% | 90% | 100% | 100% | 0% | 100% | 80% | 100% | 31% | 80% | 87% |
| fable | 62% | 60% | 95% | 90% | 58% | 80% | 0% | 80% | 100% | 100% | 0% | 100% | 80% | 100% | 43% | 85% | 90% |

## By question

Number of correct answers out of the querying models, per layer.

| id | question | none | reference | muse | haiku | sonnet | opus | fable |
|---|---|---|---|---|---|---|---|---|
| q01 | What was our MRR at the end of June 2025, in USD? | 2/5 | 5/5 | 5/5 | 0/5 | 4/5 | 5/5 | 5/5 |
| q02 | What was ARR at the end of December 2024? | 0/5 | 5/5 | 4/5 | 0/5 | 0/5 | 5/5 | 5/5 |
| q03 | How many paying customers did we have at the end of March 2025? | 1/5 | 5/5 | 4/5 | 2/5 | 0/5 | 0/5 | 0/5 |
| q04 | What was ARPA at the end of June 2025? | 2/5 | 5/5 | 5/5 | 1/5 | 5/5 | 0/5 | 0/5 |
| q05 | How many customers churned in May 2025? | 1/5 | 5/5 | 5/5 | 1/5 | 0/5 | 5/5 | 5/5 |
| q06 | What was the logo churn rate in April 2025? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q07 | What were total billings in January through March 2025? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 5/5 | 5/5 |
| q08 | What were total billings in fiscal year 2025? | 1/5 | 4/5 | 5/5 | 0/5 | 0/5 | 5/5 | 4/5 |
| q09 | How much revenue did we recognize in March 2025? | 2/5 | 5/5 | 5/5 | 0/5 | 1/5 | 5/5 | 5/5 |
| q10 | How much revenue did we recognize in Q3 of fiscal 2025? | 3/5 | 5/5 | 4/5 | 0/5 | 2/5 | 5/5 | 5/5 |
| q11 | How much cash did we collect in June 2025? | 2/5 | 5/5 | 5/5 | 3/5 | 2/5 | 5/5 | 5/5 |
| q12 | What was the total amount refunded to customers in 2024? | 2/5 | 5/5 | 5/5 | 2/5 | 0/5 | 5/5 | 5/5 |
| q13 | How many billable API calls did customers make in May 2025? | 4/5 | 5/5 | 5/5 | 3/5 | 1/5 | 5/5 | 5/5 |
| q14 | What was MRR from EMEA customers at the end of June 2025? | 3/5 | 5/5 | 5/5 | 1/5 | 5/5 | 0/5 | 1/5 |
| q15 | What was MRR from the Enterprise segment at the end of December 2024? | 1/5 | 5/5 | 5/5 | 3/5 | 0/5 | 0/5 | 5/5 |
| q16 | How many paying customers were on an annual plan at the end of June 2025? | 1/5 | 5/5 | 3/5 | 0/5 | 5/5 | 0/5 | 0/5 |
| q17 | What were new-business bookings in Q4 of fiscal 2025? | 4/5 | 5/5 | 4/5 | 4/5 | 4/5 | 5/5 | 5/5 |
| q18 | What were total bookings in calendar year 2024? | 5/5 | 5/5 | 5/5 | 2/5 | 5/5 | 5/5 | 5/5 |
| q19 | What was our win rate in the first half of 2025? | 5/5 | 5/5 | 4/5 | 5/5 | 5/5 | 5/5 | 4/5 |
| q20 | What was the EMEA Sales team's win rate in 2024? | 4/5 | 5/5 | 5/5 | 4/5 | 5/5 | 4/5 | 4/5 |
| q21 | How much did MRR grow between the end of June 2024 and the end of June 2025? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 5/5 | 5/5 |
| q22 | What were 2024 billings from customers billed in Japanese yen, in USD? | 0/5 | 5/5 | 4/5 | 0/5 | 0/5 | 1/5 | 3/5 |
| q23 | What share of June 2025 billings came from services invoices? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 5/5 | 5/5 |
| q24 | What was net cash, meaning cash collected minus refunds, in April through June 2025? | 1/5 | 5/5 | 5/5 | 2/5 | 0/5 | 5/5 | 5/5 |
| q25 | How many paying customers were on a Growth plan at the end of December 2024? | 1/5 | 4/5 | 1/5 | 1/5 | 0/5 | 0/5 | 0/5 |
| q26 | How many billable API calls did Enterprise-segment customers make in January through March 2025? | 4/5 | 5/5 | 5/5 | 4/5 | 4/5 | 0/5 | 1/5 |
| q27 | What was ARR from customers billed in British pounds at the end of June 2025, in USD? | 3/5 | 4/5 | 5/5 | 2/5 | 5/5 | 2/5 | 4/5 |
| q28 | How many new customers did we add in April through June 2025? | 2/5 | 5/5 | 5/5 | 0/5 | 5/5 | 0/5 | 0/5 |
| q29 | How many customers churned in calendar year 2024 in total? | 0/5 | 5/5 | 5/5 | 0/5 | 0/5 | 0/5 | 0/5 |
| q30 | Which sales rep had the highest bookings in fiscal year 2025? | 5/5 | 4/5 | 4/5 | 5/5 | 4/5 | 5/5 | 5/5 |

## Runs

1050 graded sessions, 2 ended without a structured answer.

| querier | median seconds | sessions |
|---|---|---|
| muse | 165 | 210 |
| haiku | 17 | 210 |
| sonnet | 20 | 210 |
| opus | 17 | 210 |
| fable | 30 | 210 |
