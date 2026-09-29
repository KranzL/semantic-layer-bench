{{ config(materialized='table', schema='marts') }}

-- Deduplicated, account-and-plan-enriched, month-end snapshot of every
-- subscription. Source data occasionally has two subscription_version rows
-- that both claim to cover the same subscription_id + month_end (seen when a
-- correction version has a malformed valid_from/valid_to pair). We resolve
-- that by keeping the version with the latest valid_from as of the month
-- end, which always matches the version that has no such conflict.
with month_ends as (
    -- Bounded to the last month with observed billing activity (invoices,
    -- payments and usage events all end 2025-06-30). fx_rates and the
    -- open-ended (valid_to is null) subscription versions would otherwise
    -- extrapolate "active" subscriptions into future calendar months that
    -- have no corroborating billing data.
    select date_day as month_end
    from {{ ref('dim_date') }}
    where is_month_end and date_day <= date '2025-06-30'
),

versions as (
    select
        s.subscription_id,
        s.account_id,
        m.month_end,
        v.version_id,
        v.valid_from,
        v.status,
        v.plan_id,
        v.seats,
        v.unit_price_minor,
        v.discount_pct,
        s.currency,
        c.minor_unit_exponent,
        fx.usd_per_unit,
        row_number() over (
            partition by s.subscription_id, m.month_end
            order by v.valid_from desc, v.version_id desc
        ) as rn
    from {{ ref('stg_subscriptions') }} s
    join {{ ref('stg_subscription_versions') }} v on v.subscription_id = s.subscription_id
    join month_ends m on v.valid_from <= m.month_end and (v.valid_to is null or m.month_end < v.valid_to)
    join {{ ref('stg_currencies') }} c on c.currency = s.currency
    join {{ ref('stg_fx_rates') }} fx on fx.currency = s.currency and fx.rate_date = m.month_end
)

select
    v.subscription_id || '-' || cast(v.month_end as varchar) as subscription_month_id,
    v.subscription_id,
    v.account_id,
    v.month_end,
    v.status,
    v.status in ('active', 'past_due') as is_paying,
    v.plan_id,
    p.plan_name,
    p.plan_family,
    p.billing_interval,
    v.seats,
    v.currency,
    a.segment,
    a.region,
    a.country,
    -- Seat price for the version's own billing interval, converted to a
    -- monthly recurring amount in USD (annual plans are billed once a year
    -- for a price that is not simply 12x the monthly price, so we divide the
    -- annual seat price by 12 rather than assuming parity with the monthly plan).
    round(
        v.seats * v.unit_price_minor * (1 - v.discount_pct) * v.usd_per_unit
        / power(10, v.minor_unit_exponent)
        / case when p.billing_interval = 'year' then 12.0 else 1.0 end
    , 2) as mrr_usd
from versions v
join {{ ref('stg_plans') }} p on p.plan_id = v.plan_id
join {{ ref('dim_accounts') }} a on a.account_id = v.account_id
where v.rn = 1
  and not a.is_internal
