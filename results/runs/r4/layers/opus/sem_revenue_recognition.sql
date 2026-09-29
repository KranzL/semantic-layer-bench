{{ config(materialized='table', schema='marts') }}

-- Recognized revenue per invoice per calendar month, in USD at the invoice's issue-date FX rate.
-- Subscription invoices are recognized ratably by day over the service period; services
-- invoices are recognized in full on the issue date (logic in fct_revenue_recognition).
-- Excludes draft and void invoices (never finalized / cancelled) and internal/test accounts.
-- Amounts are net of invoice discounts and exclude tax. Credit notes are NOT deducted.
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as revenue_row_id,
    r.invoice_id,
    r.account_id,
    i.subscription_id,
    r.invoice_type,
    r.status as invoice_status,
    r.currency,
    r.recognized_month as month_start,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) as recognized_revenue_local,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_revenue_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('fct_invoices') }} i on i.invoice_id = r.invoice_id
join {{ ref('dim_accounts') }} a on a.account_id = r.account_id
where r.status not in ('draft', 'void')
  and not a.is_internal
