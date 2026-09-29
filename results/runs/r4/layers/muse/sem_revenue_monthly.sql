{{ config(materialized='table', schema='marts') }}

select
    r.invoice_id,
    r.account_id,
    r.invoice_type,
    r.status,
    r.recognized_month,
    r.currency,
    case
        when r.status not in ('draft', 'void')
        then r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit
        else 0
    end as recognized_revenue_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('dim_accounts') }} a on a.account_id = r.account_id
where not a.is_internal and not a.is_deleted
