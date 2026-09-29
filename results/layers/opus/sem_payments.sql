{{ config(materialized='table', schema='marts') }}

-- Successful customer payments (cash received). Excludes failed payment
-- attempts and payments from internal accounts. USD at the received-date FX rate.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    p.received_date,
    p.method,
    p.currency,
    p.amount_minor / power(10, p.minor_unit_exponent) as amount_local,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from {{ ref('fct_payments') }} p
join {{ ref('dim_accounts') }} a on a.account_id = p.account_id
where p.status = 'succeeded'
  and not a.is_internal
  and not a.is_deleted
