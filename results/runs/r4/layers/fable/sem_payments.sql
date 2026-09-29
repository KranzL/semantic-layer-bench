{{ config(materialized='table', schema='semantic') }}

-- Payment attempts of reportable accounts with amounts converted to USD at the
-- received-date FX rate. Only status = 'succeeded' moved cash.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    a.customer_id,
    i.plan_id,
    i.invoice_type,
    p.received_date,
    p.status,
    p.status = 'succeeded' as is_succeeded,
    p.method,
    p.currency,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from {{ ref('fct_payments') }} p
join {{ ref('sem_accounts') }} a on a.account_id = p.account_id
left join {{ ref('sem_invoices') }} i on i.invoice_id = p.invoice_id
