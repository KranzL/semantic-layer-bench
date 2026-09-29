{{ config(materialized='table', schema='marts') }}

-- One row per external account per calendar month in which the account was paying at the
-- month-end snapshot, or was paying at the previous month-end (so logo churn is visible).
-- "Paying" = at least one subscription in status 'active' with MRR > 0 on the month-end date
-- (see sem_subscription_months). Internal/test accounts are excluded.
with account_mrr as (
    select
        account_id,
        month_end,
        sum(mrr_usd) as mrr_usd,
        sum(seats) as seats,
        arg_max(plan_id, mrr_usd) as primary_plan_id
    from {{ ref('sem_subscription_months') }}
    group by 1, 2
    having sum(mrr_usd) > 0
),
month_ends as (
    select distinct month_end from {{ ref('fct_subscription_months') }}
),
first_paid as (
    select account_id, min(month_end) as first_paid_month_end
    from account_mrr
    group by 1
),
grid as (
    select f.account_id, f.first_paid_month_end, m.month_end
    from first_paid f
    join month_ends m on m.month_end >= f.first_paid_month_end
),
series as (
    select
        g.account_id,
        g.month_end,
        g.first_paid_month_end,
        coalesce(am.mrr_usd, 0) as mrr_usd,
        am.seats,
        am.primary_plan_id,
        am.account_id is not null as is_paying,
        lag(am.account_id is not null) over (partition by g.account_id order by g.month_end) as was_paying_prior,
        lag(am.primary_plan_id) over (partition by g.account_id order by g.month_end) as prior_plan_id
    from grid g
    left join account_mrr am on am.account_id = g.account_id and am.month_end = g.month_end
)
select
    account_id || '|' || cast(month_end as varchar) as customer_month_id,
    account_id,
    cast(date_trunc('month', month_end) as date) as month_start,
    month_end,
    coalesce(primary_plan_id, prior_plan_id) as plan_id,
    mrr_usd,
    case when is_paying then 1 else 0 end as is_paying_customer,
    case when coalesce(was_paying_prior, false) then 1 else 0 end as was_paying_prior_month,
    case when is_paying and month_end = first_paid_month_end then 1 else 0 end as is_new_customer,
    case when is_paying and month_end > first_paid_month_end and not was_paying_prior then 1 else 0 end as is_reactivated_customer,
    case when not is_paying and was_paying_prior then 1 else 0 end as is_churned_customer
from series
where is_paying or coalesce(was_paying_prior, false)
