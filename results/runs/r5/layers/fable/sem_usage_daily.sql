{{ config(materialized='table', schema='semantic') }}

-- One row per real account per day of billable usage. Only api_call events
-- are billable; health_check events (automated heartbeats, a constant 288
-- per account per day) are removed, as are internal and soft-deleted accounts.
select
    u.account_id || '|' || cast(u.usage_date as varchar) as usage_day_id,
    u.account_id,
    a.customer_id,
    u.usage_date,
    cast(u.quantity as bigint) as billable_quantity
from {{ ref('fct_usage_daily') }} u
join {{ ref('sem_accounts') }} a on a.account_id = u.account_id
where u.event_type = 'api_call'
