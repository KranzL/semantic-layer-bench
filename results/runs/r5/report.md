# Results

Accuracy by querying model (rows) and semantic layer (columns). A layer column is the model that built the layer; `none` has no layer and `reference` is the layer written from the finance definitions.

| querier | none | reference | muse | haiku | sonnet | opus | fable | all |
|---|---|---|---|---|---|---|---|---|
| muse | 43% (13/30) | 100% (30/30) | 100% (30/30) | 40% (12/30) | 53% (16/30) | 60% (18/30) | 57% (17/30) | 65% (136/210) |
| haiku | 7% (2/30) | 90% (27/30) | 73% (22/30) | 13% (4/30) | 40% (12/30) | 60% (18/30) | 43% (13/30) | 47% (98/210) |
| sonnet | 57% (17/30) | 100% (30/30) | 100% (30/30) | 17% (5/30) | 53% (16/30) | 63% (19/30) | 57% (17/30) | 64% (134/210) |
| opus | 57% (17/30) | 100% (30/30) | 100% (30/30) | 30% (9/30) | 53% (16/30) | 63% (19/30) | 57% (17/30) | 66% (138/210) |
| all | 41% (49/120) | 98% (117/120) | 93% (112/120) | 25% (30/120) | 50% (60/120) | 62% (74/120) | 53% (64/120) | - |

## By question area

| layer | billings | cash | churn | customers | mrr | refunds | revenue | sales | usage |
|---|---|---|---|---|---|---|---|---|---|
| none | 0% | 50% | 0% | 19% | 50% | 50% | 38% | 85% | 75% |
| reference | 100% | 100% | 100% | 94% | 100% | 100% | 100% | 90% | 100% |
| muse | 88% | 100% | 100% | 81% | 96% | 100% | 100% | 90% | 100% |
| haiku | 6% | 12% | 0% | 12% | 7% | 25% | 0% | 85% | 75% |
| sonnet | 100% | 100% | 0% | 0% | 21% | 100% | 100% | 90% | 0% |
| opus | 81% | 100% | 33% | 0% | 54% | 100% | 88% | 95% | 50% |
| fable | 94% | 100% | 33% | 0% | 11% | 100% | 100% | 90% | 50% |

## By trap

Accuracy on questions that exercise each trap.

| layer | annual | event_type | fiscal | fx | internal | minor_units | new_definition | open_opps | opp_type | payment_status | plan_version | recognition | rep_team | stage | status | tax | void_draft |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| none | 50% | 75% | 56% | 38% | 33% | 38% | 0% | 75% | 100% | 50% | 25% | 38% | 75% | 88% | 30% | 0% | 12% |
| reference | 100% | 100% | 94% | 100% | 99% | 100% | 100% | 88% | 100% | 100% | 75% | 100% | 75% | 88% | 98% | 100% | 100% |
| muse | 94% | 100% | 88% | 96% | 95% | 100% | 100% | 88% | 100% | 100% | 75% | 100% | 100% | 88% | 93% | 88% | 92% |
| haiku | 6% | 75% | 44% | 17% | 13% | 0% | 0% | 75% | 75% | 12% | 0% | 0% | 50% | 100% | 7% | 6% | 4% |
| sonnet | 19% | 0% | 94% | 75% | 32% | 88% | 0% | 88% | 100% | 100% | 0% | 100% | 100% | 88% | 11% | 100% | 100% |
| opus | 47% | 50% | 94% | 75% | 55% | 62% | 0% | 88% | 100% | 100% | 0% | 88% | 75% | 100% | 34% | 81% | 83% |
| fable | 9% | 50% | 94% | 62% | 38% | 50% | 0% | 88% | 100% | 100% | 0% | 100% | 100% | 88% | 12% | 94% | 96% |

## By question

Number of correct answers out of the querying models, per layer.

| id | question | none | reference | muse | haiku | sonnet | opus | fable |
|---|---|---|---|---|---|---|---|---|
| q01 | What was our MRR at the end of June 2025, in USD? | 3/4 | 4/4 | 4/4 | 0/4 | 3/4 | 4/4 | 0/4 |
| q02 | What was ARR at the end of December 2024? | 1/4 | 4/4 | 4/4 | 0/4 | 0/4 | 4/4 | 0/4 |
| q03 | How many paying customers did we have at the end of March 2025? | 0/4 | 4/4 | 3/4 | 2/4 | 0/4 | 0/4 | 0/4 |
| q04 | What was ARPA at the end of June 2025? | 3/4 | 4/4 | 4/4 | 0/4 | 0/4 | 0/4 | 0/4 |
| q05 | How many customers churned in May 2025? | 0/4 | 4/4 | 4/4 | 0/4 | 0/4 | 4/4 | 4/4 |
| q06 | What was the logo churn rate in April 2025? | 0/4 | 4/4 | 4/4 | 0/4 | 0/4 | 0/4 | 0/4 |
| q07 | What were total billings in January through March 2025? | 0/4 | 4/4 | 4/4 | 1/4 | 4/4 | 4/4 | 4/4 |
| q08 | What were total billings in fiscal year 2025? | 0/4 | 4/4 | 3/4 | 0/4 | 4/4 | 4/4 | 4/4 |
| q09 | How much revenue did we recognize in March 2025? | 2/4 | 4/4 | 4/4 | 0/4 | 4/4 | 4/4 | 4/4 |
| q10 | How much revenue did we recognize in Q3 of fiscal 2025? | 1/4 | 4/4 | 4/4 | 0/4 | 4/4 | 3/4 | 4/4 |
| q11 | How much cash did we collect in June 2025? | 2/4 | 4/4 | 4/4 | 1/4 | 4/4 | 4/4 | 4/4 |
| q12 | What was the total amount refunded to customers in 2024? | 2/4 | 4/4 | 4/4 | 1/4 | 4/4 | 4/4 | 4/4 |
| q13 | How many billable API calls did customers make in May 2025? | 3/4 | 4/4 | 4/4 | 3/4 | 0/4 | 4/4 | 4/4 |
| q14 | What was MRR from EMEA customers at the end of June 2025? | 3/4 | 4/4 | 4/4 | 0/4 | 0/4 | 0/4 | 0/4 |
| q15 | What was MRR from the Enterprise segment at the end of December 2024? | 0/4 | 4/4 | 4/4 | 0/4 | 0/4 | 2/4 | 0/4 |
| q16 | How many paying customers were on an annual plan at the end of June 2025? | 2/4 | 4/4 | 3/4 | 0/4 | 0/4 | 0/4 | 0/4 |
| q17 | What were new-business bookings in Q4 of fiscal 2025? | 4/4 | 4/4 | 4/4 | 3/4 | 4/4 | 4/4 | 4/4 |
| q18 | What were total bookings in calendar year 2024? | 3/4 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 | 4/4 |
| q19 | What was our win rate in the first half of 2025? | 3/4 | 4/4 | 3/4 | 4/4 | 3/4 | 4/4 | 3/4 |
| q20 | What was the EMEA Sales team's win rate in 2024? | 3/4 | 3/4 | 4/4 | 2/4 | 4/4 | 3/4 | 4/4 |
| q21 | How much did MRR grow between the end of June 2024 and the end of June 2025? | 1/4 | 4/4 | 4/4 | 0/4 | 0/4 | 4/4 | 0/4 |
| q22 | What were 2024 billings from customers billed in Japanese yen, in USD? | 0/4 | 4/4 | 4/4 | 0/4 | 4/4 | 1/4 | 4/4 |
| q23 | What share of June 2025 billings came from services invoices? | 0/4 | 4/4 | 3/4 | 0/4 | 4/4 | 4/4 | 3/4 |
| q24 | What was net cash, meaning cash collected minus refunds, in April through June 2025? | 2/4 | 4/4 | 4/4 | 0/4 | 4/4 | 4/4 | 4/4 |
| q25 | How many paying customers were on a Growth plan at the end of December 2024? | 1/4 | 3/4 | 3/4 | 0/4 | 0/4 | 0/4 | 0/4 |
| q26 | How many billable API calls did Enterprise-segment customers make in January through March 2025? | 3/4 | 4/4 | 4/4 | 3/4 | 0/4 | 0/4 | 0/4 |
| q27 | What was ARR from customers billed in British pounds at the end of June 2025, in USD? | 3/4 | 4/4 | 3/4 | 2/4 | 3/4 | 1/4 | 3/4 |
| q28 | How many new customers did we add in April through June 2025? | 0/4 | 4/4 | 4/4 | 0/4 | 0/4 | 0/4 | 0/4 |
| q29 | How many customers churned in calendar year 2024 in total? | 0/4 | 4/4 | 4/4 | 0/4 | 0/4 | 0/4 | 0/4 |
| q30 | Which sales rep had the highest bookings in fiscal year 2025? | 4/4 | 3/4 | 3/4 | 4/4 | 3/4 | 4/4 | 3/4 |

## Runs

840 graded sessions, 0 ended without a structured answer.

| querier | median seconds | sessions |
|---|---|---|
| muse | 131 | 210 |
| haiku | 18 | 210 |
| sonnet | 12 | 210 |
| opus | 17 | 210 |
