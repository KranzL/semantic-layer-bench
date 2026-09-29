{{ config(materialized='table', schema='semantic') }}

-- Customer ("logo") lifecycle by month: one row per top-level customer per calendar month end,
-- for every month from the customer's first paying month onward, plus the month after any
-- paying month (so churn months are present). Rolls up all billing accounts under a parent.
-- Internal and soft-deleted accounts are excluded (via sl_subscription_months).
--
-- A customer is paying in a month when at least one of its subscriptions has status
-- 'active' or 'past_due' at that month end. Trialing-only customers are not paying.
-- Lifecycle flags compare each month with the immediately preceding month end:
--   is_new         : paying this month, never paying in any earlier month.
--   is_reactivated : paying this month, not paying last month, but paying in some earlier month.
--   is_churned     : not paying this month, paying last month (counted in the first
--                    non-paying month). A later reactivation does not undo the churn.
-- MRR movements are in USD at each month-end FX rate, so they include FX effects.
with sub_months as (
    select * from {{ ref('sl_subscription_months') }}
),
month_ends as (
    select distinct month_end from sub_months
),
customer_month_agg as (
    select
        customer_id,
        month_end,
        sum(mrr_usd) as mrr_usd,
        sum(paid_seats) as paid_seats,
        count(*) filter (where is_paying) as paying_subscriptions,
        count(*) filter (where is_trialing) as trialing_subscriptions,
        count(distinct account_id) filter (where is_paying) as paying_accounts
    from sub_months
    group by 1, 2
),
customers as (
    select customer_id, min(month_end) as first_month
    from customer_month_agg
    where paying_subscriptions > 0
    group by 1
),
grid as (
    select c.customer_id, m.month_end
    from customers c
    cross join month_ends m
    where m.month_end >= c.first_month
),
joined as (
    select
        g.customer_id,
        g.month_end,
        coalesce(a.mrr_usd, 0) as mrr_usd,
        coalesce(a.paid_seats, 0) as paid_seats,
        coalesce(a.paying_subscriptions, 0) as paying_subscriptions,
        coalesce(a.trialing_subscriptions, 0) as trialing_subscriptions,
        coalesce(a.paying_accounts, 0) as paying_accounts,
        coalesce(a.paying_subscriptions, 0) > 0 as is_paying
    from grid g
    left join customer_month_agg a on a.customer_id = g.customer_id and a.month_end = g.month_end
),
seq as (
    select
        *,
        coalesce(lag(is_paying) over w, false) as was_paying_prior_month,
        coalesce(lag(mrr_usd) over w, 0) as prior_month_mrr_usd,
        coalesce(lag(paid_seats) over w, 0) as prior_month_paid_seats,
        coalesce(max(case when is_paying then 1 else 0 end) over (
            partition by customer_id order by month_end
            rows between unbounded preceding and 1 preceding
        ), 0) = 1 as was_ever_paying_before
    from joined
    window w as (partition by customer_id order by month_end)
),
flagged as (
    select
        *,
        is_paying and not was_paying_prior_month and not was_ever_paying_before as is_new,
        is_paying and not was_paying_prior_month and was_ever_paying_before as is_reactivated,
        not is_paying and was_paying_prior_month as is_churned,
        is_paying and was_paying_prior_month as is_retained
    from seq
)
select
    customer_id || '|' || cast(month_end as varchar) as customer_month_id,
    customer_id,
    month_end,
    cast(date_trunc('month', month_end) as date) as calendar_month,
    is_paying,
    was_paying_prior_month,
    is_new,
    is_reactivated,
    is_churned,
    is_retained,
    case
        when is_new then 'new'
        when is_reactivated then 'reactivated'
        when is_churned then 'churned'
        when is_retained then 'retained'
        else 'inactive'
    end as lifecycle_status,
    mrr_usd,
    prior_month_mrr_usd,
    paid_seats,
    prior_month_paid_seats,
    paying_subscriptions,
    trialing_subscriptions,
    paying_accounts,
    case when is_new then mrr_usd else 0 end as new_mrr_usd,
    case when is_reactivated then mrr_usd else 0 end as reactivation_mrr_usd,
    case when is_retained and mrr_usd > prior_month_mrr_usd then mrr_usd - prior_month_mrr_usd else 0 end as expansion_mrr_usd,
    case when is_retained and mrr_usd < prior_month_mrr_usd then prior_month_mrr_usd - mrr_usd else 0 end as contraction_mrr_usd,
    case when is_churned then prior_month_mrr_usd else 0 end as churned_mrr_usd
from flagged
where is_paying or was_paying_prior_month
