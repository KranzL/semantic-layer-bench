{{ config(materialized='table', schema='semantic') }}

-- One row per customer (logo) per month in which the customer was paying at
-- month-end, or had been paying at the previous month-end (the churn month).
-- Classifies each row as new / reactivated / retained / churned and carries
-- the MRR movement between the two month-ends.
with paying as (
    select
        customer_id,
        month_start,
        sum(mrr_usd) as mrr_usd
    from {{ ref('sem_subscription_months') }}
    group by all
),
bounds as (
    select max(month_start) as last_month from paying
),
first_paying as (
    select customer_id, min(month_start) as first_paying_month
    from paying
    group by all
),
candidates as (
    select customer_id, month_start from paying
    union
    select p.customer_id, cast(p.month_start + interval 1 month as date) as month_start
    from paying p
    cross join bounds b
    where p.month_start < b.last_month
),
joined as (
    select
        c.customer_id,
        c.month_start,
        f.first_paying_month,
        coalesce(cur.mrr_usd, 0) as mrr_usd,
        coalesce(prev.mrr_usd, 0) as prior_mrr_usd,
        cur.customer_id is not null as is_paying,
        prev.customer_id is not null as was_paying_prior_month
    from candidates c
    join first_paying f on f.customer_id = c.customer_id
    left join paying cur
        on cur.customer_id = c.customer_id and cur.month_start = c.month_start
    left join paying prev
        on prev.customer_id = c.customer_id
        and prev.month_start = cast(c.month_start - interval 1 month as date)
)
select
    customer_id || '|' || cast(month_start as varchar) as customer_month_id,
    customer_id,
    month_start,
    first_paying_month,
    is_paying,
    was_paying_prior_month,
    case
        when is_paying and month_start = first_paying_month then 'new'
        when is_paying and not was_paying_prior_month then 'reactivated'
        when is_paying then 'retained'
        else 'churned'
    end as customer_movement,
    mrr_usd,
    prior_mrr_usd,
    mrr_usd - prior_mrr_usd as mrr_change_usd
from joined
