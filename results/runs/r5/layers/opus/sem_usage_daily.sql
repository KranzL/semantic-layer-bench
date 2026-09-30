{{ config(materialized='table', schema='semantic') }}

-- One row per account, day and event type on reportable accounts. Only api_call events are
-- billable; health_check events are automated system pings and never billed.
select
    u.account_id || '|' || cast(u.usage_date as varchar) || '|' || u.event_type as usage_row_id,
    u.account_id,
    a.customer_id,
    u.usage_date,
    u.event_type,
    u.event_type = 'api_call' as is_billable,
    u.quantity,
    case when u.event_type = 'api_call' then u.quantity else 0 end as billable_quantity
from {{ ref('fct_usage_daily') }} u
join {{ ref('sem_accounts') }} a on a.account_id = u.account_id
where a.is_reportable
