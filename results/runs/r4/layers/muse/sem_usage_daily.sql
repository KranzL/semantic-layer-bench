{{ config(materialized='table', schema='marts') }}

select
    u.account_id,
    u.usage_date,
    u.event_type,
    u.quantity,
    case when u.event_type = 'api_call' then u.quantity else 0 end as billable_quantity
from {{ ref('fct_usage_daily') }} u
join {{ ref('dim_accounts') }} a on a.account_id = u.account_id
where not a.is_internal and not a.is_deleted
