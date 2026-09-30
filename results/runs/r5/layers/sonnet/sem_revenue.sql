{{ config(materialized='table', schema='marts') }}

-- Recognized revenue by invoice and month for external customers.
-- Subscription invoices are recognized daily over the service period, services invoices on the issue date.
-- Drafts and voids are excluded. Months after the latest invoice month are excluded because that revenue is only scheduled.
select
    r.invoice_id,
    r.account_id,
    r.recognized_month,
    r.invoice_type,
    r.status,
    r.currency,
    a.segment,
    a.region,
    a.country,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('dim_accounts') }} a on a.account_id = r.account_id
where r.status in ('open', 'paid', 'uncollectible')
  and not a.is_internal
  and r.recognized_month <= (select cast(date_trunc('month', max(issued_date)) as date) from {{ ref('fct_invoices') }})
