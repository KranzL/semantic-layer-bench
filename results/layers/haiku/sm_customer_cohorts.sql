-- Helper model for customer acquisition and churn
with first_subscription as (
  select
    account_id,
    min(month_end) as first_month
  from {{ ref('fct_subscription_months') }}
  group by account_id
),
subscription_status as (
  select
    fsm.account_id,
    fsm.month_end,
    case when fsm.status in ('active', 'paused') then 1 else 0 end as is_paying,
    case when lag(fsm.status) over (partition by fsm.account_id order by fsm.month_end) in ('active', 'paused')
         and fsm.status not in ('active', 'paused') then 1 else 0 end as churned_this_month,
    case when fsm.month_end = fc.first_month then 1 else 0 end as is_new_customer
  from {{ ref('fct_subscription_months') }} fsm
  left join first_subscription fc on fc.account_id = fsm.account_id
)
select
  account_id,
  month_end,
  is_paying,
  churned_this_month,
  is_new_customer
from subscription_status
