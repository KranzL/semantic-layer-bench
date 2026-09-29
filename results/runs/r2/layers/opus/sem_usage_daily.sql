{{ config(materialized='table', schema='marts') }}

-- Daily billable usage per account: api_call events only. health_check events
-- are automated platform pings (a constant 288 per account per day) and are not
-- billable; usage by internal accounts (QA, demo, sandbox) is excluded.
select
    u.account_id || '|' || cast(u.usage_date as varchar) as account_usage_day_id,
    u.account_id,
    a.customer_id,
    u.usage_date,
    u.quantity as api_calls
from {{ ref('fct_usage_daily') }} u
join {{ ref('sem_accounts') }} a on a.account_id = u.account_id
where a.is_reportable
  and u.event_type = 'api_call'
