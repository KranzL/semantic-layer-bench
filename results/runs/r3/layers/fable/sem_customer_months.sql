{{ config(materialized='table', schema='semantic') }}

-- One row per (non-internal) account per calendar month-end, for every account
-- that has ever had a subscription, across the full month spine of
-- sem_subscription_months. Rows exist even in months where the account has no
-- live subscription so that churn months and pre-conversion months are visible.
-- Customer-level flags (paying / new / reactivated / churned) are derived here
-- so that every customer-count metric uses exactly one definition.
with sub_months as (
    select * from {{ ref('sem_subscription_months') }}
),
months as (
    select distinct month_end from sub_months
),
accounts as (
    select distinct account_id, customer_logo_id from sub_months
),
grid as (
    select a.account_id, a.customer_logo_id, m.month_end
    from accounts a
    cross join months m
),
agg as (
    select
        account_id,
        month_end,
        sum(mrr_usd) as mrr_usd,
        sum(mrr_local) as mrr_local,
        sum(paying_seats) as paying_seats,
        count(*) as subscriptions,
        count(case when is_paying then 1 end) as paying_subscriptions,
        count(case when is_trialing then 1 end) as trialing_subscriptions,
        bool_or(is_paying) as is_paying,
        bool_or(is_trialing) as is_trialing,
        any_value(currency) as currency
    from sub_months
    group by 1, 2
),
joined as (
    select
        g.account_id,
        g.customer_logo_id,
        g.month_end,
        coalesce(agg.mrr_usd, 0) as mrr_usd,
        coalesce(agg.mrr_local, 0) as mrr_local,
        coalesce(agg.paying_seats, 0) as paying_seats,
        coalesce(agg.subscriptions, 0) as subscriptions,
        coalesce(agg.paying_subscriptions, 0) as paying_subscriptions,
        coalesce(agg.trialing_subscriptions, 0) as trialing_subscriptions,
        coalesce(agg.is_paying, false) as is_paying,
        coalesce(agg.is_trialing, false) as is_trialing,
        agg.currency
    from grid g
    left join agg on agg.account_id = g.account_id and agg.month_end = g.month_end
),
windows as (
    select
        *,
        coalesce(
            lag(is_paying) over (partition by account_id order by month_end), false
        ) as was_paying_prior_month,
        coalesce(
            lag(mrr_usd) over (partition by account_id order by month_end), 0
        ) as prior_month_mrr_usd,
        min(case when is_paying then month_end end) over (partition by account_id) as first_paying_month,
        max(case when is_paying then month_end end) over (partition by account_id) as last_paying_month
    from joined
)
select
    account_id || '|' || cast(month_end as varchar) as customer_month_id,
    account_id,
    customer_logo_id,
    month_end,
    currency,
    mrr_usd,
    mrr_local,
    paying_seats,
    subscriptions,
    paying_subscriptions,
    trialing_subscriptions,
    is_paying,
    is_trialing,
    was_paying_prior_month,
    prior_month_mrr_usd,
    first_paying_month,
    last_paying_month,
    -- first month ever in which the account has a paying subscription
    is_paying and month_end = first_paying_month as is_new_customer,
    -- paying again after at least one full month without a paying subscription
    is_paying and not was_paying_prior_month and month_end > first_paying_month as is_reactivated_customer,
    -- paying at the prior month-end, not paying at this month-end
    was_paying_prior_month and not is_paying as is_churned_customer,
    case when is_paying and month_end = first_paying_month then mrr_usd else 0 end as new_mrr_usd,
    case when was_paying_prior_month and not is_paying then prior_month_mrr_usd else 0 end as churned_mrr_usd,
    case
        when is_paying then 'paying'
        when is_trialing then 'trialing'
        when last_paying_month is not null and month_end > last_paying_month then 'churned'
        when first_paying_month is not null and month_end < first_paying_month then 'not_yet_paying'
        else 'never_paying'
    end as customer_status
from windows
