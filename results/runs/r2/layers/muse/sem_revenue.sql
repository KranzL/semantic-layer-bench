select
    r.invoice_id || '|' || cast(r.recognized_month as varchar) as row_key,
    r.recognized_month,
    r.invoice_id,
    r.invoice_type,
    r.status as invoice_status,
    r.currency,
    r.account_id,
    a.account_name,
    a.segment,
    a.region,
    a.country,
    a.billing_currency,
    a.parent_account_id,
    case
        when r.status not in ('draft', 'void')
        then r.recognized_amount_minor / power(10, r.minor_unit_exponent) * r.usd_per_unit
        else 0
    end as recognized_usd
from {{ ref('fct_revenue_recognition') }} r
join {{ ref('dim_accounts') }} a on a.account_id = r.account_id
where not a.is_internal and not a.is_deleted
