{{ config(materialized='table', schema='marts') }}

-- One row per customer (ultimate parent account) per month end in which the
-- customer was paying at that month end or at the previous month end.
-- "Paying" = at least one active or past_due subscription (MRR > 0) on an
-- external, non-deleted account in the customer's hierarchy at month end.
-- Flags classify each customer-month as new, reactivated, retained or churned,
-- and split the MRR change into new / reactivation / expansion / contraction /
-- churn movements. MRR is in USD at each month's month-end FX rate, so
-- expansion and contraction include FX translation effects for non-USD customers.
with months as (
    select date_day as month_end
    from {{ ref('dim_date') }}
    where is_month_end and date_day between date '2023-01-31' and date '2025-06-30'
),
paying as (
    select customer_id, month_end, sum(mrr_usd) as mrr_usd
    from {{ ref('sem_subscription_months') }}
    where is_paying
    group by all
),
firsts as (
    select customer_id, min(month_end) as first_paying_month
    from paying
    group by all
),
grid as (
    select f.customer_id, f.first_paying_month, m.month_end,
        cast(last_day(m.month_end - interval 1 month) as date) as prev_month_end
    from firsts f
    join months m on m.month_end >= f.first_paying_month
),
flags as (
    select
        g.customer_id,
        g.month_end,
        g.first_paying_month,
        coalesce(cur.mrr_usd, 0) as mrr_usd,
        coalesce(prev.mrr_usd, 0) as prev_mrr_usd,
        cur.customer_id is not null as is_paying,
        prev.customer_id is not null as was_paying
    from grid g
    left join paying cur on cur.customer_id = g.customer_id and cur.month_end = g.month_end
    left join paying prev on prev.customer_id = g.customer_id and prev.month_end = g.prev_month_end
)
select
    f.customer_id || '|' || cast(f.month_end as varchar) as customer_month_id,
    f.customer_id,
    f.month_end,
    case
        when f.is_paying and f.month_end = f.first_paying_month then 'new'
        when f.is_paying and not f.was_paying then 'reactivated'
        when f.is_paying and f.was_paying then 'retained'
        else 'churned'
    end as customer_status,
    cast(f.is_paying as int) as is_paying,
    cast(f.was_paying as int) as was_paying,
    cast(f.is_paying and f.month_end = f.first_paying_month as int) as is_new,
    cast(f.is_paying and not f.was_paying and f.month_end > f.first_paying_month as int) as is_reactivated,
    cast(f.was_paying and not f.is_paying as int) as is_churned,
    f.mrr_usd,
    f.prev_mrr_usd,
    case when f.is_paying and f.month_end = f.first_paying_month then f.mrr_usd else 0 end as new_mrr_usd,
    case when f.is_paying and not f.was_paying and f.month_end > f.first_paying_month then f.mrr_usd else 0 end as reactivation_mrr_usd,
    case when f.is_paying and f.was_paying and f.mrr_usd > f.prev_mrr_usd then f.mrr_usd - f.prev_mrr_usd else 0 end as expansion_mrr_usd,
    case when f.is_paying and f.was_paying and f.mrr_usd < f.prev_mrr_usd then f.prev_mrr_usd - f.mrr_usd else 0 end as contraction_mrr_usd,
    case when f.was_paying and not f.is_paying then f.prev_mrr_usd else 0 end as churned_mrr_usd
from flags f
where f.is_paying or f.was_paying
