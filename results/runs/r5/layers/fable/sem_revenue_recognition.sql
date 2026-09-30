{{ config(materialized='table', schema='semantic') }}

-- One row per invoice per month of revenue recognition, for finalized
-- invoices (open, paid, uncollectible) of real accounts. Draft and void
-- invoices and internal / soft-deleted accounts are removed. Amounts exclude
-- tax, are net of invoice discounts, and are converted to USD at the FX rate
-- of the invoice issue date.
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as revenue_line_id,
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
where r.status in ('open', 'paid', 'uncollectible')
