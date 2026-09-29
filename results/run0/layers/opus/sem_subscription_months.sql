-- Month-end snapshot of paying subscriptions (status active or past_due), one row per subscription per month.
-- Excludes trialing and canceled versions and internal accounts. Where two subscription versions overlap on a
-- month end (bad source data), the version with the latest valid_from wins so a subscription is never counted twice.
with month_ends as (
    select date_day as month_end
    from {{ ref('dim_date') }}
    where is_month_end and date_day between date '2023-01-31' and date '2025-06-30'
),

versions_at_month_end as (
    select
        s.subscription_id,
        s.account_id,
        s.currency,
        m.month_end,
        v.version_id,
        v.status,
        v.plan_id,
        v.seats,
        v.unit_price_minor,
        v.discount_pct,
        row_number() over (
            partition by s.subscription_id, m.month_end
            order by v.valid_from desc, v.version_id desc
        ) as version_rank
    from {{ ref('stg_subscriptions') }} s
    join {{ ref('stg_subscription_versions') }} v on v.subscription_id = s.subscription_id
    join month_ends m on v.valid_from <= m.month_end and (v.valid_to is null or m.month_end < v.valid_to)
)

select
    v.subscription_id || '|' || cast(v.month_end as varchar) as subscription_month_id,
    v.subscription_id,
    v.account_id,
    a.customer_id,
    cast(date_trunc('month', v.month_end) as date) as snapshot_month,
    v.month_end,
    v.status,
    v.plan_id,
    p.plan_name,
    p.plan_family,
    p.billing_interval,
    v.currency,
    v.seats,
    v.discount_pct,
    -- monthly recurring amount in the subscription currency (major units), after discount, excluding tax;
    -- annual plans are divided by 12
    v.seats * v.unit_price_minor * (1 - v.discount_pct)
        / case when p.billing_interval = 'year' then 12 else 1 end
        / power(10, c.minor_unit_exponent) as mrr_local,
    v.seats * v.unit_price_minor * (1 - v.discount_pct)
        / case when p.billing_interval = 'year' then 12 else 1 end
        / power(10, c.minor_unit_exponent) * fx.usd_per_unit as mrr_usd
from versions_at_month_end v
join {{ ref('sem_accounts') }} a on a.account_id = v.account_id
join {{ ref('stg_plans') }} p on p.plan_id = v.plan_id
join {{ ref('stg_currencies') }} c on c.currency = v.currency
join {{ ref('stg_fx_rates') }} fx on fx.currency = v.currency and fx.rate_date = v.month_end
where v.version_rank = 1
  and v.status in ('active', 'past_due')
