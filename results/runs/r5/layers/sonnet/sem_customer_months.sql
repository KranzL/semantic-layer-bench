{{ config(materialized='table', schema='marts') }}

-- Customer x month-end grid from each customer's first paying month through the last month-end.
-- A customer is paying at a month-end when any of its subscriptions is live (active or past_due) then.
with months as (
    select distinct month_end from {{ ref('sem_subscription_months') }}
),
per_customer as (
    select
        customer_id,
        month_end,
        sum(mrr_usd) as mrr_usd,
        max_by(plan_id, mrr_usd) as plan_id,
        max_by(plan_family, mrr_usd) as plan_family,
        max_by(billing_interval, mrr_usd) as billing_interval,
        max_by(currency, mrr_usd) as currency
    from {{ ref('sem_subscription_months') }}
    group by all
),
first_paid as (
    select customer_id, min(month_end) as first_paid_month from per_customer group by all
),
grid as (
    select f.customer_id, m.month_end
    from first_paid f
    join months m on m.month_end >= f.first_paid_month
),
joined as (
    select
        g.customer_id,
        g.month_end,
        pc.customer_id is not null as is_paying,
        coalesce(pc.mrr_usd, 0) as mrr_usd,
        last_value(pc.plan_id ignore nulls) over w as plan_id,
        last_value(pc.plan_family ignore nulls) over w as plan_family,
        last_value(pc.billing_interval ignore nulls) over w as billing_interval,
        last_value(pc.currency ignore nulls) over w as currency,
        f.first_paid_month
    from grid g
    join first_paid f on f.customer_id = g.customer_id
    left join per_customer pc on pc.customer_id = g.customer_id and pc.month_end = g.month_end
    window w as (partition by g.customer_id order by g.month_end)
),
flagged as (
    select
        *,
        coalesce(lag(is_paying) over w2, false) as was_paying_prior_month,
        lag(mrr_usd) over w2 as prior_mrr_usd
    from joined
    window w2 as (partition by customer_id order by month_end)
)
select
    f.customer_id,
    f.month_end,
    a.segment,
    a.region,
    a.country,
    f.plan_id,
    f.plan_family,
    f.billing_interval,
    f.currency,
    f.mrr_usd,
    f.is_paying,
    f.was_paying_prior_month,
    f.is_paying and f.month_end = f.first_paid_month as is_new_customer,
    f.was_paying_prior_month and not f.is_paying as is_churned_customer,
    case when f.was_paying_prior_month and not f.is_paying then f.prior_mrr_usd else 0 end as churned_mrr_usd,
    cast(f.is_paying as integer) as paying_customer,
    cast(f.is_paying and f.month_end = f.first_paid_month as integer) as new_customer,
    cast(f.was_paying_prior_month and not f.is_paying as integer) as churned_customer,
    cast(f.was_paying_prior_month as integer) as opening_customer
from flagged f
join {{ ref('dim_accounts') }} a on a.account_id = f.customer_id
