{{ config(materialized='table', schema='semantic') }}

-- One row per payment attempt, excluding internal accounts, with amounts in
-- major currency units and in USD at the FX rate on the day received.
-- status is 'succeeded' or 'failed'. Only succeeded payments are cash.
-- Every paid invoice has exactly one succeeded payment for its full total
-- (including tax); failed attempts are retries that never moved money.
with payments as (
    select * from {{ ref('fct_payments') }}
),
inv as (
    select invoice_id, customer_id, invoice_type, plan_id, plan_family, billing_interval, issued_date
    from {{ ref('sem_invoices') }}
)
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    i.customer_id,
    i.invoice_type,
    i.plan_id,
    i.plan_family,
    i.billing_interval,
    p.received_at,
    p.received_date,
    i.issued_date                                             as invoice_issued_date,
    datediff('day', i.issued_date, p.received_date)           as days_to_pay,
    p.status,
    p.method,
    p.currency,
    p.minor_unit_exponent,
    p.usd_per_unit,
    p.status = 'succeeded'                                    as is_succeeded,
    p.status = 'failed'                                       as is_failed,
    p.amount_minor / power(10, p.minor_unit_exponent)                    as amount_local,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit   as amount_usd
from payments p
join inv i on i.invoice_id = p.invoice_id
