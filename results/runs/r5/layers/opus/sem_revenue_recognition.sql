{{ config(materialized='table', schema='semantic') }}

-- One row per invoice per recognition month. Subscription invoices are recognized ratably by day
-- over the service period; services invoices in full on the issue date. Only issued invoices
-- (open, paid, uncollectible) on reportable accounts; draft and void invoices are excluded.
-- Revenue is net of invoice discounts, excludes tax, and is not reduced by credit notes.
-- USD at the invoice issue-date FX rate.
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as revenue_line_id,
    r.invoice_id,
    r.account_id,
    a.customer_id,
    i.plan_id,
    r.invoice_type,
    r.recognized_month,
    r.currency,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) as recognized_amount_local,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_amount_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('sem_accounts') }} a on a.account_id = r.account_id
join {{ ref('sem_invoices') }} i on i.invoice_id = r.invoice_id
where a.is_reportable
  and r.status in ('open', 'paid', 'uncollectible')
