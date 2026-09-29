select
    plan_id,
    plan_name,
    plan_family,
    billing_interval,
    list_price_usd_minor
from {{ ref('stg_plans') }}
