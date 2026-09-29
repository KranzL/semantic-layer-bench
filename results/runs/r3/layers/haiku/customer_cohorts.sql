-- Identifies when each customer became a customer (first subscription month)
with account_months as (
  select distinct
    account_id,
    date_trunc('month', cast(created_date as timestamp)) as month_start
  from {{ ref('accounts') }}
  union all
  select distinct
    account_id,
    date_trunc('month', cast(month_end as timestamp)) as month_start
  from {{ ref('fct_subscription_months') }}
),
first_subscription_per_account as (
  select
    account_id,
    min(cast(date_trunc('month', created_at) as date)) as first_subscription_month
  from {{ ref('stg_subscriptions') }}
  where created_at is not null
  group by account_id
)
select
  a.account_id,
  fs.first_subscription_month,
  am.month_start,
  case
    when am.month_start = fs.first_subscription_month then true
    else false
  end as is_first_subscription_month
from account_months am
join first_subscription_per_account fs on am.account_id = fs.account_id
where am.month_start >= fs.first_subscription_month
