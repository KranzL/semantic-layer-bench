with subscription_months as (
    select
        account_id,
        month_end,
        status,
        lag(status) over (partition by account_id order by month_end) as prev_status,
        lag(month_end) over (partition by account_id order by month_end) as prev_month_end
    from {{ ref('fct_subscription_months') }}
),
churned_month as (
    select distinct
        prev_month_end as churn_month,
        account_id,
        case when prev_status = 'active' and status != 'active' then 1 else 0 end as is_churned
    from subscription_months
    where datediff('month', prev_month_end, month_end) = 1
        and prev_status = 'active'
        and status != 'active'
)
select
    churn_month,
    account_id,
    1 as churned_flag
from churned_month
where is_churned = 1
