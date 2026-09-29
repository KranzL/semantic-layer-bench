with month_ends as (
    select date_day as month_end
    from {{ ref('dim_date') }}
    where is_month_end and date_day between date '2023-01-31' and date '2025-06-30'
)
select
    s.subscription_id,
    s.account_id,
    m.month_end,
    v.version_id,
    v.status,
    v.plan_id,
    p.billing_interval,
    v.seats,
    v.unit_price_minor,
    v.discount_pct,
    s.currency,
    c.minor_unit_exponent,
    fx.usd_per_unit
from {{ ref('stg_subscriptions') }} s
join {{ ref('stg_subscription_versions') }} v on v.subscription_id = s.subscription_id
join month_ends m on v.valid_from <= m.month_end and (v.valid_to is null or m.month_end < v.valid_to)
join {{ ref('stg_plans') }} p on p.plan_id = v.plan_id
join {{ ref('stg_currencies') }} c on c.currency = s.currency
join {{ ref('stg_fx_rates') }} fx on fx.currency = s.currency and fx.rate_date = m.month_end
