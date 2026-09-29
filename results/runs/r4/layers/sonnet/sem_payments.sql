{{ config(materialized='table') }}
-- Payment attempts on invoices of external accounts, in USD at the receipt-date FX rate.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    p.received_date,
    p.status,
    p.method,
    p.currency,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from {{ ref('fct_payments') }} p
join {{ ref('sem_accounts') }} a on a.account_id = p.account_id
