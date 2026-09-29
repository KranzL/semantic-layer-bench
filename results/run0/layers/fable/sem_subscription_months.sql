{{ config(materialized='table', schema='semantic') }}

-- Month-end snapshot of every subscription, one row per subscription per
-- month_end, with recurring revenue already computed.
-- Cleaning applied versus marts.fct_subscription_months:
--   * overlapping subscription versions produce duplicate rows; keep only the
--     version with the latest valid_from (the newest version supersedes).
--   * internal accounts (is_internal) are removed.
--   * customer_id rolls child accounts up to their parent account.
-- MRR logic: seats x per-seat price x (1 - discount) per billing interval,
-- divided by 12 for annual plans, converted from minor units to major units
-- using the currency's minor_unit_exponent, and to USD at the month-end FX rate.
-- Only 'active' and 'past_due' subscriptions carry MRR. Trialing and canceled
-- rows are kept for counting but have mrr = 0.
with snapshot as (
    select
        f.*,
        v.valid_from,
        row_number() over (
            partition by f.subscription_id, f.month_end
            order by v.valid_from desc, f.version_id desc
        ) as rn
    from {{ ref('fct_subscription_months') }} f
    join {{ ref('stg_subscription_versions') }} v on v.version_id = f.version_id
),
accounts as (
    select
        account_id,
        coalesce(parent_account_id, account_id) as customer_id,
        is_internal
    from {{ ref('dim_accounts') }}
),
plans as (
    select plan_id, plan_family from {{ ref('dim_plans') }}
),
base as (
    select
        s.subscription_id,
        s.account_id,
        a.customer_id,
        s.month_end,
        s.version_id,
        s.status,
        s.plan_id,
        p.plan_family,
        s.billing_interval,
        s.seats,
        s.unit_price_minor,
        s.discount_pct,
        s.currency,
        s.minor_unit_exponent,
        s.usd_per_unit,
        s.status in ('active', 'past_due') as is_paying,
        s.status = 'trialing'              as is_trialing,
        s.status = 'canceled'              as is_canceled,
        s.discount_pct > 0                 as has_discount,
        -- contracted monthly recurring amount in local major currency units
        s.seats * s.unit_price_minor * (1 - s.discount_pct)
            / power(10, s.minor_unit_exponent)
            / case when s.billing_interval = 'year' then 12.0 else 1.0 end as contracted_mrr_local
    from snapshot s
    join accounts a on a.account_id = s.account_id
    join plans p on p.plan_id = s.plan_id
    where s.rn = 1
      and not a.is_internal
)
select
    subscription_id || '|' || cast(month_end as varchar) as subscription_month_id,
    subscription_id,
    account_id,
    customer_id,
    month_end,
    version_id,
    status,
    plan_id,
    plan_family,
    billing_interval,
    seats,
    unit_price_minor,
    discount_pct,
    currency,
    minor_unit_exponent,
    usd_per_unit,
    is_paying,
    is_trialing,
    is_canceled,
    has_discount,
    contracted_mrr_local,
    contracted_mrr_local * usd_per_unit                                   as contracted_mrr_usd,
    case when is_paying then contracted_mrr_local else 0 end              as mrr_local,
    case when is_paying then contracted_mrr_local * usd_per_unit else 0 end as mrr_usd,
    case when is_paying then seats else 0 end                             as paying_seats
from base
