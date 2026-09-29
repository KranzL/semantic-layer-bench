select
    sm.subscription_id,
    sm.account_id,
    sm.month_end,
    sm.version_id,
    sm.status,
    sm.plan_id,
    sm.billing_interval,
    sm.seats,
    sm.unit_price_minor,
    sm.discount_pct,
    sm.currency,
    case
        when sm.status in ('active', 'past_due')
            and not a.is_internal
            and a.deleted_at is null
        then 1
        else 0
    end as is_paying,
    case
        when sm.status in ('active', 'past_due')
            and not a.is_internal
            and a.deleted_at is null
        then (sm.seats * sm.unit_price_minor * (1 - sm.discount_pct)
                / case when sm.billing_interval = 'year' then 12.0 else 1.0 end)
            / power(10, sm.minor_unit_exponent) * sm.usd_per_unit
        else 0
    end as mrr_usd
from {{ ref('fct_subscription_months') }} sm
join {{ ref('dim_accounts') }} a on a.account_id = sm.account_id
