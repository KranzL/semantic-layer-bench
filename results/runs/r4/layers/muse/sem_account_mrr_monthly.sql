{{ config(materialized='table', schema='marts') }}

with account_months as (
    select
        m.account_id,
        m.month_end,
        max(case when m.status in ('active', 'past_due') then 1 else 0 end) as is_paying,
        sum(case when m.status in ('active', 'past_due') then m.mrr_usd else 0 end) as mrr_usd
    from {{ ref('sem_subscription_mrr') }} m
    group by 1, 2
),
flagged as (
    select
        account_id,
        month_end,
        mrr_usd,
        is_paying = 1 as is_paying,
        coalesce(
            lag(is_paying) over (partition by account_id order by month_end) = 1,
            false
        ) as was_paying_prev_month,
        min(case when is_paying = 1 then month_end end) over (partition by account_id) as first_paying_month
    from account_months
)
select
    account_id,
    month_end,
    mrr_usd,
    is_paying,
    was_paying_prev_month,
    (is_paying and month_end = first_paying_month) as is_new_customer,
    (was_paying_prev_month and not is_paying) as is_churned,
    case when is_paying then 1 else 0 end as paying_flag,
    case when is_paying and month_end = first_paying_month then account_id end as new_account_id,
    case when was_paying_prev_month and not is_paying then account_id end as churned_account_id,
    case when was_paying_prev_month then account_id end as cohort_start_account_id
from flagged
