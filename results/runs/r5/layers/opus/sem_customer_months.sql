{{ config(materialized='table', schema='semantic') }}

-- One row per customer (ultimate parent) per calendar month from the customer's first
-- subscription month through 2025-06. A customer is paying in a month when any of its (or its
-- subsidiaries') subscriptions is active or past_due at month end, i.e. has MRR > 0.
with sub_months as (
    select
        customer_id,
        cast(date_trunc('month', snapshot_date) as date) as snapshot_month,
        sum(mrr_usd) as mrr_usd,
        bool_or(is_paying) as is_paying
    from {{ ref('sem_subscription_months') }}
    group by all
),
months as (
    select distinct calendar_month as snapshot_month
    from {{ ref('dim_date') }}
    where calendar_month between date '2023-01-01' and date '2025-06-01'
),
grid as (
    select c.customer_id, m.snapshot_month
    from (select customer_id, min(snapshot_month) as first_month from sub_months group by 1) c
    join months m on m.snapshot_month >= c.first_month
),
filled as (
    select
        g.customer_id,
        g.snapshot_month,
        coalesce(s.mrr_usd, 0) as mrr_usd,
        coalesce(s.is_paying, false) as is_paying
    from grid g
    left join sub_months s using (customer_id, snapshot_month)
),
flagged as (
    select
        *,
        coalesce(lag(is_paying) over (partition by customer_id order by snapshot_month), false) as was_paying_prior_month,
        min(case when is_paying then snapshot_month end) over (partition by customer_id) as first_paying_month
    from filled
)
select
    customer_id || '|' || cast(snapshot_month as varchar) as customer_month_id,
    customer_id,
    cast(last_day(snapshot_month) as date) as snapshot_date,
    first_paying_month,
    mrr_usd,
    is_paying,
    was_paying_prior_month,
    case when is_paying then 1 else 0 end as paying_flag,
    case when was_paying_prior_month then 1 else 0 end as beginning_paying_flag,
    case when snapshot_month = first_paying_month then 1 else 0 end as new_flag,
    case when is_paying and not was_paying_prior_month and snapshot_month > first_paying_month then 1 else 0 end as reactivated_flag,
    case when was_paying_prior_month and not is_paying then 1 else 0 end as churned_flag
from flagged
