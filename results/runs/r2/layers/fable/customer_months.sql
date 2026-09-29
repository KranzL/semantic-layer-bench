{{ config(materialized='table', schema='marts') }}

/*
    One row per external (non-internal) account per month-end snapshot, for every month in
    which the account was a paying customer at this month end or at the previous month end.

    Feeds the customer-flow metrics (new, churned and reactivated customers, MRR movements,
    churn rates). A "paying customer" is an account with a subscription version whose status
    is active or past_due in force on the month-end date. Trialing and canceled subscriptions
    do not count. Snapshots are month-end only, so a churn-and-return inside a single month
    is not visible here.
*/

with month_ends as (
    select distinct month_end from {{ ref('fct_subscription_months') }}
),

external_accounts as (
    select account_id from {{ ref('dim_accounts') }} where not is_internal
),

paying as (
    select
        account_id,
        month_end,
        subscription_id,
        plan_id,
        billing_interval,
        status as subscription_status,
        currency,
        seats,
        seats * unit_price_minor * (1 - discount_pct)
            / power(10, minor_unit_exponent) * usd_per_unit
            / (case when billing_interval = 'year' then 12.0 else 1.0 end) as mrr_usd
    from {{ ref('fct_subscription_months') }}
    where status in ('active', 'past_due')
),

grid as (
    select a.account_id, m.month_end
    from external_accounts a
    cross join month_ends m
),

joined as (
    select
        g.account_id,
        g.month_end,
        p.subscription_id,
        p.plan_id,
        p.billing_interval,
        p.subscription_status,
        p.currency,
        coalesce(p.seats, 0) as seats,
        coalesce(p.mrr_usd, 0) as mrr_usd,
        p.account_id is not null as is_paying
    from grid g
    left join paying p on p.account_id = g.account_id and p.month_end = g.month_end
),

windowed as (
    select
        *,
        coalesce(lag(is_paying) over w, false) as was_paying_prior_month,
        coalesce(lag(mrr_usd) over w, 0) as prior_month_mrr_usd,
        coalesce(lag(seats) over w, 0) as prior_month_seats,
        lag(plan_id) over w as prior_month_plan_id,
        lag(billing_interval) over w as prior_month_billing_interval,
        lag(currency) over w as prior_month_currency,
        lag(subscription_id) over w as prior_month_subscription_id,
        min(case when is_paying then month_end end) over (partition by account_id) as first_paying_month_end
    from joined
    window w as (partition by account_id order by month_end)
),

flagged as (
    select
        *,
        is_paying and month_end = first_paying_month_end as is_new_customer,
        is_paying and not was_paying_prior_month and month_end > first_paying_month_end as is_reactivated_customer,
        not is_paying and was_paying_prior_month as is_churned_customer,
        is_paying and was_paying_prior_month as is_retained_customer
    from windowed
    where is_paying or was_paying_prior_month
)

select
    account_id || '|' || cast(month_end as varchar) as customer_month_id,
    account_id,
    month_end,
    coalesce(subscription_id, prior_month_subscription_id) as subscription_id,
    coalesce(plan_id, prior_month_plan_id) as plan_id,
    coalesce(billing_interval, prior_month_billing_interval) as billing_interval,
    coalesce(currency, prior_month_currency) as currency,
    subscription_status,
    is_paying,
    was_paying_prior_month,
    is_new_customer,
    is_reactivated_customer,
    is_churned_customer,
    is_retained_customer,
    case
        when is_new_customer then 'new'
        when is_reactivated_customer then 'reactivated'
        when is_churned_customer then 'churned'
        when is_retained_customer and mrr_usd > prior_month_mrr_usd then 'expansion'
        when is_retained_customer and mrr_usd < prior_month_mrr_usd then 'contraction'
        else 'retained_flat'
    end as customer_movement,
    first_paying_month_end,
    seats,
    prior_month_seats,
    mrr_usd,
    prior_month_mrr_usd,
    case when is_new_customer then mrr_usd else 0 end as new_mrr_usd,
    case when is_reactivated_customer then mrr_usd else 0 end as reactivation_mrr_usd,
    case when is_retained_customer and mrr_usd > prior_month_mrr_usd then mrr_usd - prior_month_mrr_usd else 0 end as expansion_mrr_usd,
    case when is_retained_customer and mrr_usd < prior_month_mrr_usd then prior_month_mrr_usd - mrr_usd else 0 end as contraction_mrr_usd,
    case when is_churned_customer then prior_month_mrr_usd else 0 end as churned_mrr_usd
from flagged
