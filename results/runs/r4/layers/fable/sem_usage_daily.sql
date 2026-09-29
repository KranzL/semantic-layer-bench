{{ config(materialized='table', schema='semantic') }}

-- Daily usage per account and event type for reportable accounts. Only api_call events are
-- billable; health_check events are automated monitoring pings (a constant 288 per day).
select
    u.account_id || '|' || cast(u.usage_date as varchar) || '|' || u.event_type as usage_daily_id,
    u.account_id,
    a.customer_id,
    u.usage_date,
    u.event_type,
    u.event_type = 'api_call' as is_billable,
    cast(u.quantity as bigint) as quantity
from {{ ref('fct_usage_daily') }} u
join {{ ref('sem_accounts') }} a on a.account_id = u.account_id
