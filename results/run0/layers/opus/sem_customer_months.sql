-- One row per customer per month in which the customer was paying at month end and/or was paying at the
-- previous month end. Drives paying customers, new, reactivated and churned logo counts.
-- A customer is "paying" at a month end if any of its (or its subsidiaries') subscriptions is active or past_due
-- at that month end (see sem_subscription_months). Internal accounts are excluded.
with months as (
    select distinct snapshot_month from {{ ref('sem_subscription_months') }}
),

paying as (
    select customer_id, snapshot_month, sum(mrr_usd) as mrr_usd
    from {{ ref('sem_subscription_months') }}
    group by all
),

first_paid as (
    select customer_id, min(snapshot_month) as first_paid_month
    from paying
    group by 1
),

candidates as (
    select customer_id, snapshot_month from paying
    union
    select p.customer_id, cast(p.snapshot_month + interval 1 month as date)
    from paying p
    where cast(p.snapshot_month + interval 1 month as date) in (select snapshot_month from months)
)

select
    c.customer_id || '|' || cast(c.snapshot_month as varchar) as customer_month_id,
    c.customer_id,
    c.snapshot_month,
    cur.customer_id is not null as is_paying,
    prev.customer_id is not null as was_paying_prior_month,
    coalesce(cur.mrr_usd, 0) as mrr_usd,
    coalesce(prev.mrr_usd, 0) as prior_month_mrr_usd,
    case when cur.customer_id is not null then 1 else 0 end as paying_flag,
    case when prev.customer_id is not null then 1 else 0 end as prior_month_paying_flag,
    case when cur.customer_id is not null and c.snapshot_month = f.first_paid_month then 1 else 0 end as new_flag,
    case when cur.customer_id is not null and prev.customer_id is null and c.snapshot_month > f.first_paid_month then 1 else 0 end as reactivated_flag,
    case when cur.customer_id is null and prev.customer_id is not null then 1 else 0 end as churned_flag
from candidates c
join first_paid f on f.customer_id = c.customer_id
left join paying cur on cur.customer_id = c.customer_id and cur.snapshot_month = c.snapshot_month
left join paying prev on prev.customer_id = c.customer_id and prev.snapshot_month = cast(c.snapshot_month - interval 1 month as date)
