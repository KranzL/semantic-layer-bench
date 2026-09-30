{{ config(materialized='table') }}
with base as (
    select
        account_id,
        month_end,
        sum(mrr_usd) as mrr_usd,
        count_if(mrr_usd > 0) > 0 as is_paying
    from {{ ref('subscription_mrr_monthly') }}
    group by account_id, month_end
),
flagged as (
    select
        account_id,
        month_end,
        mrr_usd,
        is_paying,
        coalesce(lag(is_paying) over (partition by account_id order by month_end), false) as was_paying,
        min(case when is_paying then month_end end) over (partition by account_id) as first_paying_month
    from base
)
select
    account_id || '|' || cast(month_end as varchar) as customer_month_id,
    account_id,
    month_end,
    mrr_usd,
    is_paying,
    was_paying,
    (is_paying and month_end = first_paying_month) as is_new_customer,
    (was_paying and not is_paying) as churned
from flagged
