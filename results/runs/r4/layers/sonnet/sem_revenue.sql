{{ config(materialized='table') }}
-- Monthly recognized revenue per invoice for external accounts, in USD at the invoice issue-date FX rate.
-- Months after the month of the latest issued invoice are future schedule, not yet recognized, and are dropped.
select
    r.invoice_id,
    r.account_id,
    r.invoice_type,
    r.status,
    r.recognized_month,
    r.currency,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('sem_accounts') }} a on a.account_id = r.account_id
where r.recognized_month <= (select cast(date_trunc('month', max(issued_date)) as date) from {{ ref('fct_invoices') }})
