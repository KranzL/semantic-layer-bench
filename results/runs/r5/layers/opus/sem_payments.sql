{{ config(materialized='table', schema='semantic') }}

-- One row per payment attempt on a reportable account (succeeded and failed).
-- USD at the received-date FX rate.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    a.customer_id,
    p.received_date,
    p.status as payment_status,
    p.method as payment_method,
    p.currency,
    p.amount_minor / power(10, p.minor_unit_exponent) as amount_local,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from {{ ref('fct_payments') }} p
join {{ ref('sem_accounts') }} a on a.account_id = p.account_id
where a.is_reportable
