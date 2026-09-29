{{ config(materialized='table', schema='marts') }}

-- Recognized revenue per invoice per calendar month. Subscription invoices are
-- recognized ratably by day over the service period; services invoices are
-- recognized in full on the issue date. Amounts are net of invoice discounts,
-- exclude tax, and are converted to USD at the invoice issue-date FX rate.
-- Only finalized invoices (open, paid, uncollectible) of external, non-deleted
-- accounts are included; draft and void invoices are excluded.
-- Credit notes/refunds are not netted here (see the refunds metric).
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as revenue_month_id,
    r.invoice_id,
    r.account_id,
    a.customer_id,
    i.plan_id,
    r.invoice_type,
    r.status as invoice_status,
    r.recognized_month,
    r.currency,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_revenue_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('sem_accounts') }} a on a.account_id = r.account_id
join {{ ref('sem_invoices') }} i on i.invoice_id = r.invoice_id
where a.is_reportable
  and r.status in ('open', 'paid', 'uncollectible')
