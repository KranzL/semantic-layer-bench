{{ config(materialized='table', schema='semantic') }}

-- One row per payment attempt against an invoice of a non-internal account.
-- Amounts are converted to major units and to USD at the FX rate on the day
-- the payment was received. Both succeeded and failed attempts are kept;
-- cash measures filter to succeeded explicitly.
with payments as (
    select * from {{ ref('fct_payments') }}
),
invoices as (
    select invoice_id, invoice_type from {{ ref('fct_invoices') }}
),
accounts as (
    select account_id, is_internal from {{ ref('dim_accounts') }}
)
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    i.invoice_type,
    p.received_date,
    p.status as payment_status,
    p.method as payment_method,
    p.currency,
    p.minor_unit_exponent,
    p.usd_per_unit,
    p.status = 'succeeded' as is_succeeded,
    p.amount_minor / power(10, p.minor_unit_exponent) as amount_local,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from payments p
join invoices i on i.invoice_id = p.invoice_id
join accounts a on a.account_id = p.account_id
where not a.is_internal
