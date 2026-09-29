with subscription_months as (
    select distinct
        account_id,
        month_end,
        row_number() over (partition by account_id order by month_end) as month_number
    from {{ ref('fct_subscription_months') }}
    where status = 'active'
)
select
    account_id,
    min(month_end) as first_active_month,
    max(month_end) as last_active_month,
    max(month_number) as total_active_months
from subscription_months
group by account_id
