{{ config(materialized='table', schema='semantic') }}

-- Monthly revenue recognition schedule per invoice for reportable accounts, in USD at the
-- invoice's issue-date FX rate. Carries the invoice's plan so revenue can be sliced by plan.
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as revenue_schedule_id,
    r.invoice_id,
    r.account_id,
    i.customer_id,
    i.plan_id,
    r.invoice_type,
    r.status,
    r.status in ('open', 'paid', 'uncollectible') as is_billed,
    r.recognized_month,
    cast(last_day(r.recognized_month) as date) as recognized_month_end,
    r.currency,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_amount_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('sem_invoices') }} i on i.invoice_id = r.invoice_id
