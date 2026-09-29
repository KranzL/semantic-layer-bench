select
    account_id,
    usage_date,
    event_type,
    sum(quantity) as quantity
from {{ ref('stg_usage_events') }}
group by all
