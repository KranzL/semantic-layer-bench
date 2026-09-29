{{ config(materialized='table', schema='semantic') }}

-- Month-end snapshot of every subscription: one row per subscription per calendar month end
-- (2023-01-31 .. 2025-06-30), taken from the subscription version in force on that day.
-- Internal and soft-deleted accounts are excluded.
--
-- Pricing in the source is per seat, per billing interval, in the subscription currency's
-- minor units (cents, pence, whole yen). MRR here is:
--     seats * unit price * (1 - discount_pct) / 10^minor_unit_exponent  -> local major units
--     / 12 for annual plans                                              -> monthly
--     * usd_per_unit at the month-end FX rate                            -> USD
-- Only versions with status 'active' or 'past_due' are paying (is_paying). 'trialing'
-- and 'canceled' versions carry zero MRR and zero paid seats.
with snap as (
    select * from {{ ref('fct_subscription_months') }}
),
accounts as (
    select * from {{ ref('sl_accounts') }} where is_reportable
),
plans as (
    select * from {{ ref('dim_plans') }}
),
subs as (
    select * from {{ ref('stg_subscriptions') }}
),
base as (
    select
        s.subscription_id || '|' || cast(s.month_end as varchar) as subscription_month_id,
        s.subscription_id,
        s.version_id,
        s.account_id,
        a.customer_id,
        s.month_end,
        cast(date_trunc('month', s.month_end) as date) as calendar_month,
        s.status,
        s.status in ('active', 'past_due') as is_paying,
        s.status = 'trialing' as is_trialing,
        s.plan_id,
        p.plan_name,
        p.plan_family,
        s.billing_interval,
        s.currency,
        s.minor_unit_exponent,
        s.usd_per_unit,
        s.seats as contracted_seats,
        s.unit_price_minor,
        s.discount_pct,
        s.unit_price_minor / power(10, s.minor_unit_exponent) as unit_price_local,
        s.seats * s.unit_price_minor * (1 - s.discount_pct) / power(10, s.minor_unit_exponent)
            / case when s.billing_interval = 'year' then 12.0 else 1.0 end as gross_mrr_local,
        cast(sub.created_at as date) as subscription_created_date,
        sub.trial_start,
        sub.trial_end,
        cast(sub.canceled_at as date) as canceled_date,
        sub.ended_at as ended_date
    from snap s
    join accounts a on a.account_id = s.account_id
    join plans p on p.plan_id = s.plan_id
    join subs sub on sub.subscription_id = s.subscription_id
)
select
    subscription_month_id,
    subscription_id,
    version_id,
    account_id,
    customer_id,
    month_end,
    calendar_month,
    status,
    is_paying,
    is_trialing,
    plan_id,
    plan_name,
    plan_family,
    billing_interval,
    currency,
    minor_unit_exponent,
    usd_per_unit,
    contracted_seats,
    case when is_paying then contracted_seats else 0 end as paid_seats,
    unit_price_local,
    discount_pct,
    discount_pct > 0 as has_discount,
    case when is_paying then gross_mrr_local else 0 end as mrr_local,
    case when is_paying then gross_mrr_local * usd_per_unit else 0 end as mrr_usd,
    case when is_paying then gross_mrr_local * usd_per_unit * 12 else 0 end as arr_usd,
    subscription_created_date,
    trial_start,
    trial_end,
    canceled_date,
    ended_date,
    canceled_date is not null and ended_date > month_end as is_pending_cancellation
from base
