# Relay business definitions

This is the finance team's definition sheet for Relay, a B2B SaaS company. It is the source of truth for every answer in the question set and for the reference semantic layer. No agent that builds or queries a semantic layer ever sees this file.

All data covers 2023-01-01 through 2025-06-30. All money answers are in US dollars.

## Accounts and customers

- Internal accounts (`is_internal = true`) are employee and QA accounts. They are excluded from every customer, revenue, billing, cash and usage figure.
- Deleted accounts (`deleted_at` is set) were merged duplicates. They are excluded everywhere.
- A paying subscription is one whose status is `active` or `past_due`. `trialing` and `canceled` are not paying.
- A paying customer at a date is a non-internal, non-deleted account with at least one paying subscription on that date. Customers are counted by `account_id`; subsidiaries are not rolled up to their parent.

## Money

- Amounts are stored in the currency's minor unit. USD, EUR and GBP have 2 decimal places. JPY has 0.
- Convert to USD with `usd_per_unit` from the FX table on the relevant date: the month-end date for MRR, the invoice issue date for billings and revenue, the payment date for cash, the credit note date for refunds.

## MRR and ARR

- MRR of a paying subscription at a month end = seats x unit price x (1 - discount), divided by 12 for annual plans, converted to USD at the month-end rate.
- MRR at a month end is the sum over paying subscriptions of non-internal, non-deleted accounts, using the subscription version in effect on the last day of the month.
- ARR = MRR x 12.
- ARPA at a month end = MRR / paying customers.

## Churn

- Logo churn in month M = accounts that were paying customers at the end of M-1 and are not paying customers at the end of M.
- Logo churn rate in month M = logo churn / paying customers at the end of M-1.
- A new customer in month M is an account that is a paying customer at the end of M and was not a paying customer at any earlier month end.
- Churn and new customers over a longer period are the sum of the monthly figures.

## Billings, revenue, cash, refunds

- Billings = subtotal minus discount, excluding tax, for invoices whose status is not `void` or `draft`, dated by issue date.
- Recognized revenue: subscription invoices are recognized evenly per day across their service period (`period_start` to `period_end`, end exclusive). Services invoices are recognized in full on their issue date. Void and draft invoices are excluded. Revenue uses the same amount as billings (excluding tax) and the issue-date rate.
- Cash collected = payments with status `succeeded`, dated by received date.
- Refunds = credit notes, dated by issue date.

## Usage

- Billable API calls = usage quantity where `event_type = 'api_call'`. `health_check` events are system traffic and are not billable.

## Sales

- Bookings = amount of opportunities with stage `closed_won`, dated by close date. New bookings are type `new` only.
- Win rate = closed won / (closed won + closed lost), by close date. Open opportunities are excluded.

## Attributes

- Segment, region, country and billing currency come from the account. Plan family and billing interval come from the subscription version in effect on the date in question.
- A sales team is the `team` of the opportunity's sales rep.

## Fiscal calendar

- The fiscal year starts on 1 February and is named for the calendar year it ends in. FY2025 runs 2024-02-01 to 2025-01-31.
- Fiscal quarters: Q1 is February to April, Q2 May to July, Q3 August to October, Q4 November to January.
