{{ config(materialized='table', schema='marts') }}

with base as (
    select
        m.subscription_id,
        m.account_id,
        m.month_end,
        m.version_id,
        m.status,
        m.plan_id,
        m.billing_interval,
        m.seats,
        m.currency,
        m.seats * m.unit_price_minor * (1 - m.discount_pct)
            / power(10, m.minor_unit_exponent) * m.usd_per_unit
            / case when m.billing_interval = 'year' then 12 else 1 end as full_mrr_usd
    from {{ ref('fct_subscription_months') }} m
    join {{ ref('dim_accounts') }} a on a.account_id = m.account_id
    where not a.is_internal and not a.is_deleted
)
select
    subscription_id,
    account_id,
    month_end,
    version_id,
    status,
    plan_id,
    billing_interval,
    seats,
    currency,
    status in ('active', 'past_due') as is_paying,
    case when status in ('active', 'past_due') then full_mrr_usd else 0 end as mrr_usd,
    case when status in ('active', 'past_due') then seats else 0 end as paying_seats
from base
