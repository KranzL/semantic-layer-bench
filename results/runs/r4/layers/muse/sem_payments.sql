{{ config(materialized='table', schema='marts') }}

select
    p.payment_id,
    p.invoice_id,
    p.account_id,
    p.received_at,
    p.received_date,
    p.status,
    p.method,
    p.currency,
    case
        when p.status = 'succeeded'
        then p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit
        else 0
    end as cash_collected_usd
from {{ ref('fct_payments') }} p
join {{ ref('dim_accounts') }} a on a.account_id = p.account_id
where not a.is_internal and not a.is_deleted
