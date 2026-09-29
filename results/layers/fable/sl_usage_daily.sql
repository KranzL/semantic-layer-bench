{{ config(materialized='table', schema='semantic') }}

-- Daily usage per account and event type, for reportable accounts only (internal
-- accounts, which generate a large share of raw API volume, and soft-deleted accounts are
-- excluded). Event types: 'api_call' (customer-driven, billable) and 'health_check'
-- (platform pings at a fixed 288 per account per day, never billable).
with usage as (
    select * from {{ ref('fct_usage_daily') }}
),
accounts as (
    select * from {{ ref('sl_accounts') }} where is_reportable
)
select
    u.account_id || '|' || cast(u.usage_date as varchar) || '|' || u.event_type as usage_daily_id,
    u.account_id,
    a.customer_id,
    u.usage_date,
    u.event_type,
    u.event_type = 'api_call' as is_billable,
    cast(u.quantity as bigint) as quantity,
    case when u.event_type = 'api_call' then cast(u.quantity as bigint) else 0 end as billable_quantity
from usage u
join accounts a on a.account_id = u.account_id
