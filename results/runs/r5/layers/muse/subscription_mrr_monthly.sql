{{ config(materialized='table') }}
select
    sm.subscription_id || '|' || cast(sm.month_end as varchar) as subscription_month_id,
    sm.subscription_id,
    sm.account_id,
    sm.month_end,
    sm.status,
    sm.plan_id,
    sm.billing_interval,
    sm.seats,
    sm.currency,
    sm.status in ('active', 'past_due') as is_paying,
    case
        when sm.status in ('active', 'past_due')
        then sm.seats * sm.unit_price_minor * (1 - sm.discount_pct)
            / power(10, sm.minor_unit_exponent) * sm.usd_per_unit
            / case when sm.billing_interval = 'year' then 12 else 1 end
        else 0
    end as mrr_usd
from {{ ref('fct_subscription_months') }} as sm
inner join {{ ref('dim_accounts') }} as a on a.account_id = sm.account_id
where not a.is_internal and not a.is_deleted
