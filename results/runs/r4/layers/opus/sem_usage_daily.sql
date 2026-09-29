{{ config(materialized='table', schema='marts') }}

-- Billable product usage: daily API calls per external account.
-- Excludes 'health_check' events (automated synthetic monitoring pings, a constant 288/day
-- per account, not customer usage) and all usage from internal/test accounts.
select
    u.account_id || '|' || cast(u.usage_date as varchar) as usage_day_id,
    u.account_id,
    u.usage_date,
    u.quantity as api_calls
from {{ ref('fct_usage_daily') }} u
join {{ ref('dim_accounts') }} a on a.account_id = u.account_id
where u.event_type = 'api_call'
  and not a.is_internal
