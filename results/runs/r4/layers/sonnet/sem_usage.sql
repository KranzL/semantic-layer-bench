{{ config(materialized='table') }}
-- Daily billable usage for external accounts: api_call events only (health_check pings are synthetic and not billed).
select
    u.account_id,
    u.usage_date,
    u.event_type,
    u.quantity
from {{ ref('fct_usage_daily') }} u
join {{ ref('sem_accounts') }} a on a.account_id = u.account_id
where u.event_type = 'api_call'
