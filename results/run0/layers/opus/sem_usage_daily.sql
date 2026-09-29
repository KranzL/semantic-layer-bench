-- One row per account per day per event type, external (non-internal) accounts only.
-- is_billable is true only for api_call events; health_check events are automated platform pings and are not billed.
select
    u.account_id || '|' || cast(u.usage_date as varchar) || '|' || u.event_type as usage_day_id,
    u.account_id,
    a.customer_id,
    u.usage_date,
    f.fiscal_year,
    f.fiscal_quarter,
    u.event_type,
    u.event_type = 'api_call' as is_billable,
    u.quantity
from {{ ref('fct_usage_daily') }} u
join {{ ref('sem_accounts') }} a on a.account_id = u.account_id
join {{ ref('sem_fiscal_time_spine') }} f on f.date_day = u.usage_date
