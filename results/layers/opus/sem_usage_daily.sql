{{ config(materialized='table', schema='marts') }}

-- Billable product usage per account per day: api_call events only.
-- Excludes health_check events (automated platform pings, a constant 288 per
-- account-day) and usage from internal or deleted accounts.
select
    u.account_id || '|' || cast(u.usage_date as varchar) as usage_day_id,
    u.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    u.usage_date,
    u.quantity
from {{ ref('fct_usage_daily') }} u
join {{ ref('dim_accounts') }} a on a.account_id = u.account_id
where u.event_type = 'api_call'
  and not a.is_internal
  and not a.is_deleted
