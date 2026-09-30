-- Helper model tracking customer cohorts and churn by month
with subscription_months as (
  select distinct
    account_id,
    month_end,
    status
  from {{ ref('fct_subscription_months') }}
),
monthly_status as (
  select
    account_id,
    month_end,
    max(case when status = 'active' then 1 else 0 end) as has_active_subscription
  from subscription_months
  group by account_id, month_end
),
lagged_status as (
  select
    account_id,
    month_end,
    has_active_subscription,
    lag(has_active_subscription) over (partition by account_id order by month_end) as prior_active,
    row_number() over (partition by account_id order by month_end) = 1 as is_first_month
  from monthly_status
)
select
  account_id,
  month_end,
  has_active_subscription as is_active_customer,
  is_first_month,
  case when is_first_month and has_active_subscription = 1 then 1 else 0 end as is_new_customer,
  case when prior_active = 1 and has_active_subscription = 0 then 1 else 0 end as is_churned_customer
from lagged_status
