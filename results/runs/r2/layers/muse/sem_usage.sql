select
    u.account_id || '|' || cast(u.usage_date as varchar) || '|' || u.event_type as row_key,
    u.usage_date,
    u.event_type,
    u.account_id,
    a.account_name,
    a.segment,
    a.region,
    a.country,
    a.billing_currency,
    a.parent_account_id,
    u.quantity,
    case when u.event_type = 'api_call' then u.quantity else 0 end as billable_quantity
from {{ ref('fct_usage_daily') }} u
join {{ ref('dim_accounts') }} a on a.account_id = u.account_id
where not a.is_internal and not a.is_deleted
