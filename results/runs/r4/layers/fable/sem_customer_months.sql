{{ config(materialized='table', schema='semantic') }}

-- One row per customer (logo) per month-end, from the customer's first paying month-end
-- through the latest snapshot. Classifies each month as new, retained, reactivated or churned
-- by comparing the paying state at this month-end with the previous month-end.
with customer_mrr as (
    select
        customer_id,
        month_end,
        sum(mrr_usd) as mrr_usd,
        bool_or(is_paying) as is_paying
    from {{ ref('sem_subscription_months') }}
    group by 1, 2
),
first_paying as (
    select customer_id, min(month_end) as first_paying_month_end
    from customer_mrr
    where is_paying
    group by 1
),
month_ends as (
    select distinct month_end from {{ ref('sem_subscription_months') }}
),
grid as (
    select f.customer_id, f.first_paying_month_end, m.month_end
    from first_paying f
    join month_ends m on m.month_end >= f.first_paying_month_end
),
states as (
    select
        g.customer_id,
        g.month_end,
        g.first_paying_month_end,
        coalesce(c.is_paying, false) as is_paying,
        coalesce(c.mrr_usd, 0) as mrr_usd
    from grid g
    left join customer_mrr c on c.customer_id = g.customer_id and c.month_end = g.month_end
),
lagged as (
    select
        *,
        coalesce(lag(is_paying) over (partition by customer_id order by month_end), false) as was_paying_prior_month_end
    from states
)
select
    customer_id || '|' || cast(month_end as varchar) as customer_month_id,
    customer_id,
    month_end,
    cast(date_trunc('month', month_end) as date) as snapshot_month,
    cast(date_trunc('month', first_paying_month_end) as date) as first_paying_month,
    is_paying,
    was_paying_prior_month_end,
    mrr_usd,
    case
        when is_paying and month_end = first_paying_month_end then 'new'
        when is_paying and was_paying_prior_month_end then 'retained'
        when is_paying then 'reactivated'
        when was_paying_prior_month_end then 'churned'
        else 'inactive'
    end as customer_month_status,
    case when is_paying and month_end = first_paying_month_end then 1 else 0 end as is_new_customer,
    case when is_paying and not was_paying_prior_month_end and month_end > first_paying_month_end then 1 else 0 end as is_reactivated_customer,
    case when not is_paying and was_paying_prior_month_end then 1 else 0 end as is_churned_customer,
    case when was_paying_prior_month_end then 1 else 0 end as is_customer_at_start_of_month
from lagged
