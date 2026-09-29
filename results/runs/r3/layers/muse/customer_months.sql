with months as (
    select date_day as month_end
    from {{ ref('dim_date') }}
    where is_month_end and date_day between date '2023-01-31' and date '2025-06-30'
),
paying as (
    select account_id, month_end, sum(mrr_usd) as mrr_usd, 1 as is_paying
    from {{ ref('subscription_monthly') }}
    where is_paying = 1
    group by 1, 2
),
base as (
    select
        a.account_id,
        m.month_end,
        coalesce(p.mrr_usd, 0) as mrr_usd,
        coalesce(p.is_paying, 0) as is_paying
    from {{ ref('dim_accounts') }} a
    cross join months m
    left join paying p on p.account_id = a.account_id and p.month_end = m.month_end
),
flagged as (
    select
        *,
        min(case when is_paying = 1 then month_end end) over (partition by account_id) as first_paying_month,
        lag(is_paying) over (partition by account_id order by month_end) as prev_paying_raw
    from base
)
select
    account_id,
    month_end,
    mrr_usd,
    is_paying,
    case when is_paying = 1 and month_end = first_paying_month then 1 else 0 end as is_new_paying,
    coalesce(prev_paying_raw, 0) as was_paying_prev,
    case when is_paying = 0 and coalesce(prev_paying_raw, 0) = 1 then 1 else 0 end as is_churned
from flagged
