-- Monthly customer status: identifies new customers and churned customers
with all_months as (
  select distinct cast(month_end as date) as month_end
  from {{ ref('fct_subscription_months') }}
),
account_months as (
  select distinct account_id, cast(month_end as date) as month_end
  from {{ ref('fct_subscription_months') }}
),
active_by_month as (
  -- For each account-month, determine if they had any active subscriptions
  select
    account_id,
    month_end,
    max(case when status in ('active', 'trialing') then 1 else 0 end) as has_active_subscription
  from {{ ref('fct_subscription_months') }}
  group by account_id, month_end
),
with_previous_month as (
  select
    am.account_id,
    am.month_end,
    abm.has_active_subscription,
    lag(abm.has_active_subscription, 1, 0) over (partition by am.account_id order by am.month_end) as prev_has_active_subscription
  from account_months am
  left join active_by_month abm on am.account_id = abm.account_id and am.month_end = abm.month_end
)
select
  account_id,
  month_end,
  has_active_subscription,
  case
    when has_active_subscription = 1 and prev_has_active_subscription = 0 then true
    else false
  end as is_new_customer_month,
  case
    when has_active_subscription = 0 and prev_has_active_subscription = 1 then true
    else false
  end as is_churned_customer_month
from with_previous_month
