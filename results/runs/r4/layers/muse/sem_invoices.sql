{{ config(materialized='table', schema='marts') }}

select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    i.subscription_id,
    v.plan_id,
    i.invoice_type,
    i.status,
    i.issued_at,
    i.issued_date,
    i.due_at,
    i.period_start,
    i.period_end,
    i.currency,
    case
        when i.status not in ('draft', 'void')
        then (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit
        else 0
    end as billings_usd
from {{ ref('fct_invoices') }} i
join {{ ref('dim_accounts') }} a on a.account_id = i.account_id
left join {{ ref('stg_subscription_versions') }} v
    on v.subscription_id = i.subscription_id
    and v.valid_from <= i.issued_date
    and (v.valid_to is null or i.issued_date < v.valid_to)
where not a.is_internal and not a.is_deleted
