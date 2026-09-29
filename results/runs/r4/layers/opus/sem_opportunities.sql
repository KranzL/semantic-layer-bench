{{ config(materialized='table', schema='marts') }}

-- Sales opportunities of external accounts with outcome flags. amount_usd is the annual
-- contract value (first-year ARR) of the deal in USD. Internal/test accounts are excluded.
select
    o.opportunity_id,
    o.account_id,
    o.rep_id,
    o.opportunity_type,
    o.stage,
    o.created_date,
    o.close_date,
    o.amount_usd,
    case when o.stage = 'closed_won' then 1 else 0 end as is_won,
    case when o.stage = 'closed_lost' then 1 else 0 end as is_lost,
    case when o.stage in ('closed_won', 'closed_lost') then 1 else 0 end as is_closed
from {{ ref('fct_opportunities') }} o
join {{ ref('dim_accounts') }} a on a.account_id = o.account_id
where not a.is_internal
