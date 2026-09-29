select
    o.opportunity_id,
    o.account_id,
    o.rep_id,
    o.opportunity_type,
    o.stage,
    cast(o.created_at as date) as created_date,
    o.close_date,
    o.amount_usd
from {{ ref('stg_opportunities') }} o
