{{ config(materialized='table', schema='semantic') }}

-- One row per payment attempt against an invoice, for reportable accounts only
-- (internal and soft-deleted accounts excluded). Both succeeded and failed attempts are
-- kept; only status = 'succeeded' is cash. Every succeeded payment settles one invoice in
-- full, in the invoice currency. Amounts are converted to USD at the FX rate on the day
-- the payment was received.
with pay as (
    select * from {{ ref('fct_payments') }}
),
inv as (
    select invoice_id, invoice_type from {{ ref('fct_invoices') }}
),
accounts as (
    select * from {{ ref('sl_accounts') }} where is_reportable
)
select
    p.payment_id,
    p.invoice_id,
    i.invoice_type,
    p.account_id,
    a.customer_id,
    p.received_date,
    cast(date_trunc('month', p.received_date) as date) as received_month,
    p.status,
    p.status = 'succeeded' as is_succeeded,
    p.method,
    p.currency,
    p.minor_unit_exponent,
    p.usd_per_unit,
    p.amount_minor / power(10, p.minor_unit_exponent) as amount_local,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from pay p
join accounts a on a.account_id = p.account_id
join inv i on i.invoice_id = p.invoice_id
