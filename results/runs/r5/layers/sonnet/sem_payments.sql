{{ config(materialized='table', schema='marts') }}

-- Succeeded payments from external customers, in USD at the receipt-date rate. Failed payments are excluded.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    p.received_date,
    p.method,
    p.currency,
    a.segment,
    a.region,
    a.country,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as collected_usd
from {{ ref('fct_payments') }} p
join {{ ref('dim_accounts') }} a on a.account_id = p.account_id
where p.status = 'succeeded'
  and not a.is_internal
