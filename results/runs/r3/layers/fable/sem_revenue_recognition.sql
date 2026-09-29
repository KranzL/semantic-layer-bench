{{ config(materialized='table', schema='semantic') }}

-- One row per invoice per month in which revenue from that invoice is
-- recognized, for non-internal accounts and finalized invoices only.
-- Subscription invoices are recognized ratably by day across the service
-- period (period_start inclusive to period_end exclusive); services invoices
-- are recognized in full in the month they are issued. Amounts are net of
-- discounts, exclude tax, and are converted to USD at the FX rate on the
-- invoice issue date. Draft and void invoices are excluded here.
with rev as (
    select * from {{ ref('fct_revenue_recognition') }}
),
accounts as (
    select account_id, is_internal from {{ ref('dim_accounts') }}
)
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as revenue_recognition_id,
    r.invoice_id,
    r.account_id,
    r.invoice_type,
    r.status as invoice_status,
    r.recognized_month,
    r.currency,
    r.minor_unit_exponent,
    r.usd_per_unit,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) as recognized_amount_local,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_amount_usd
from rev r
join accounts a on a.account_id = r.account_id
where not a.is_internal
  and r.status not in ('draft', 'void')
