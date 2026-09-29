{{ config(materialized='table', schema='semantic') }}

-- One row per subscription per calendar month-end (2023-01-31 .. 2025-06-30).
-- Source of truth for MRR / ARR / billable seats. Internal (Relay-owned) accounts
-- are removed here so that no downstream measure can accidentally include them.
-- Deleted accounts are kept: every deleted account's subscriptions ended on or
-- before the deletion date, so they contribute correct historical MRR and churn.
with sub_months as (
    select * from {{ ref('fct_subscription_months') }}
),
accounts as (
    select account_id, parent_account_id, is_internal from {{ ref('dim_accounts') }}
),
base as (
    select
        m.subscription_id,
        m.account_id,
        coalesce(a.parent_account_id, a.account_id) as customer_logo_id,
        m.month_end,
        m.version_id,
        m.status as subscription_status,
        m.plan_id,
        m.billing_interval,
        m.currency,
        m.seats,
        m.unit_price_minor,
        m.discount_pct,
        m.minor_unit_exponent,
        m.usd_per_unit,
        m.status in ('active', 'past_due') as is_paying,
        m.status = 'trialing' as is_trialing,
        -- Contracted recurring amount normalised to one month, in the
        -- subscription's own currency (major units, e.g. dollars not cents).
        (m.seats * m.unit_price_minor * (1 - m.discount_pct))
            / (case when m.billing_interval = 'year' then 12.0 else 1.0 end)
            / power(10, m.minor_unit_exponent) as contracted_monthly_amount_local
    from sub_months m
    join accounts a on a.account_id = m.account_id
    where not a.is_internal
)
select
    subscription_id || '|' || cast(month_end as varchar) as subscription_month_id,
    subscription_id,
    account_id,
    customer_logo_id,
    month_end,
    version_id,
    subscription_status,
    plan_id,
    billing_interval,
    currency,
    seats,
    unit_price_minor,
    discount_pct,
    minor_unit_exponent,
    usd_per_unit,
    is_paying,
    is_trialing,
    contracted_monthly_amount_local,
    contracted_monthly_amount_local * usd_per_unit as contracted_monthly_amount_usd,
    case when is_paying then contracted_monthly_amount_local else 0 end as mrr_local,
    case when is_paying then contracted_monthly_amount_local * usd_per_unit else 0 end as mrr_usd,
    case when is_paying then seats else 0 end as paying_seats
from base
