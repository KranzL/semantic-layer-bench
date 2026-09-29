-- Daily billable usage of external accounts. Only api_call events are billable; health_check heartbeats
-- (a constant 288 per day) and all usage of internal accounts are excluded.
select
    u.account_id,
    a.customer_id,
    u.usage_date,
    u.event_type,
    u.quantity as billable_units
from {{ ref('fct_usage_daily') }} u
join {{ ref('sem_accounts') }} a on a.account_id = u.account_id
where u.event_type = 'api_call'
