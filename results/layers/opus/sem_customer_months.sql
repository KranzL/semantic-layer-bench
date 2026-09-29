{{ config(materialized='table', schema='marts') }}

-- One row per customer per month-end where the customer was paying at that
-- month-end or at the previous month-end (so churn months are present).
-- A customer is the ultimate parent account (child accounts roll up to their
-- parent). A customer is "paying" at a month-end when at least one of its
-- external accounts has a subscription in status active or past_due with MRR.
with months as (
    select distinct month_end
    from {{ ref('fct_subscription_months') }}
),
paying as (
    select customer_id, month_end, sum(mrr_usd) as mrr_usd
    from {{ ref('sem_subscription_months') }}
    group by all
),
first_paid as (
    select customer_id, min(month_end) as first_paying_month_end
    from paying
    group by all
),
grid as (
    select
        c.customer_id,
        m.month_end,
        c.first_paying_month_end,
        cast(last_day(m.month_end - interval 1 month) as date) as prior_month_end
    from first_paid c
    join months m on m.month_end >= c.first_paying_month_end
),
flags as (
    select
        g.customer_id,
        g.month_end,
        g.first_paying_month_end,
        cur.customer_id is not null as is_paying,
        prev.customer_id is not null as was_paying_prior_month,
        coalesce(cur.mrr_usd, 0) as mrr_usd,
        coalesce(prev.mrr_usd, 0) as prior_month_mrr_usd
    from grid g
    left join paying cur on cur.customer_id = g.customer_id and cur.month_end = g.month_end
    left join paying prev on prev.customer_id = g.customer_id and prev.month_end = g.prior_month_end
)
select
    customer_id || '|' || cast(month_end as varchar) as customer_month_id,
    customer_id,
    month_end,
    first_paying_month_end,
    is_paying,
    was_paying_prior_month,
    is_paying and month_end = first_paying_month_end as is_new,
    is_paying and not was_paying_prior_month and month_end > first_paying_month_end as is_reactivated,
    was_paying_prior_month and not is_paying as is_churned,
    mrr_usd,
    prior_month_mrr_usd
from flags
where is_paying or was_paying_prior_month
