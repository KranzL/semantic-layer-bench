{{ config(materialized='table', schema='semantic') }}

-- Revenue recognition schedule: one row per invoice per calendar month in which part of the
-- invoice's net amount (subtotal minus discount, before tax) is recognized, for reportable
-- accounts only (internal and soft-deleted accounts excluded).
-- Subscription invoices are recognized ratably by day over the service period
-- (period_start inclusive to period_end exclusive), so annual invoices spread over 12 months
-- and can extend past the last billing month in the warehouse. Services invoices are
-- recognized in full in the month they are issued.
-- All invoice statuses are present; is_issued (open, paid, uncollectible) marks the rows
-- that count as recognized revenue. Draft and void invoices never do.
-- USD conversion uses the FX rate on the invoice issue date (the rate at which the
-- invoice was booked), not the rate of the recognition month.
with rr as (
    select * from {{ ref('fct_revenue_recognition') }}
),
accounts as (
    select * from {{ ref('sl_accounts') }} where is_reportable
)
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as revenue_recognition_id,
    r.invoice_id,
    r.account_id,
    a.customer_id,
    r.invoice_type,
    r.status as invoice_status,
    r.status in ('open', 'paid', 'uncollectible') as is_issued,
    r.recognized_month,
    r.currency,
    r.minor_unit_exponent,
    r.usd_per_unit,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) as recognized_local,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit as recognized_usd
from rr r
join accounts a on a.account_id = r.account_id
