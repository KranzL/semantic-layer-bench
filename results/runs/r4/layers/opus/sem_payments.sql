{{ config(materialized='table', schema='marts') }}

-- Successful customer payments of external accounts. Failed payment attempts and payments
-- from internal/test accounts are excluded. Amounts are the gross cash received (including
-- tax) converted to USD at the received-date FX rate.
select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    i.invoice_type,
    p.received_date,
    p.method as payment_method,
    p.currency,
    p.amount_minor / power(10, p.minor_unit_exponent) as amount_local,
    p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit as amount_usd
from {{ ref('fct_payments') }} p
join {{ ref('fct_invoices') }} i on i.invoice_id = p.invoice_id
join {{ ref('dim_accounts') }} a on a.account_id = p.account_id
where p.status = 'succeeded'
  and not a.is_internal
