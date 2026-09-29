{{ config(materialized='table', schema='semantic') }}

-- One row per invoice per month of service, excluding internal accounts.
-- marts.fct_revenue_recognition spreads each subscription invoice's net amount
-- (subtotal - discount, before tax) evenly by day across the service period and
-- books services invoices in full on the issue date. This helper adds the
-- customer, plan and USD conversion (at the invoice issue-date FX rate) and a
-- flag for which rows count as recognized revenue:
--   is_recognizable  invoice status is open, paid or uncollectible.
--                    Draft and void invoices never become revenue.
-- Uncollectible invoices remain recognized revenue (the service was delivered);
-- the write-off is tracked separately as uncollectible billings.
-- Months after the latest invoice month represent the deferred revenue schedule
-- of already-issued annual invoices.
with rev as (
    select * from {{ ref('fct_revenue_recognition') }}
),
inv as (
    select
        invoice_id,
        customer_id,
        subscription_id,
        plan_id,
        plan_family,
        billing_interval,
        issued_date
    from {{ ref('sem_invoices') }}
)
select
    r.invoice_id || '|' || cast(r.recognized_month as varchar)   as revenue_recognition_id,
    r.invoice_id,
    r.account_id,
    i.customer_id,
    i.subscription_id,
    i.plan_id,
    i.plan_family,
    i.billing_interval,
    i.issued_date                                                 as invoice_issued_date,
    r.invoice_type,
    r.status                                                      as invoice_status,
    r.recognized_month,
    r.currency,
    r.minor_unit_exponent,
    r.usd_per_unit,
    r.status not in ('draft', 'void')                             as is_recognizable,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent)                    as recognized_amount_local,
    r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit   as recognized_amount_usd
from rev r
join inv i on i.invoice_id = r.invoice_id
