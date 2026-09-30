{{ config(materialized='table', schema='marts') }}

-- Opportunities from external accounts with owner team and account attributes. Open opportunities are kept
-- but flagged so they are excluded from bookings and win rate (which only count closed deals).
select
    o.opportunity_id,
    o.account_id,
    o.rep_id,
    o.opportunity_type,
    o.stage,
    o.close_date,
    o.amount_usd,
    r.team as sales_team,
    r.region as rep_region,
    a.segment,
    a.region,
    a.country,
    cast(o.stage = 'closed_won' as integer) as is_won,
    cast(o.stage in ('closed_won', 'closed_lost') as integer) as is_closed,
    case when o.stage = 'closed_won' then o.amount_usd else 0 end as won_amount_usd,
    case when o.stage = 'closed_won' and o.opportunity_type = 'new' then o.amount_usd else 0 end as new_won_amount_usd,
    cast(o.stage = 'closed_won' and o.opportunity_type = 'new' as integer) as is_new_won,
    cast(o.stage in ('closed_won', 'closed_lost') and o.opportunity_type = 'new' as integer) as is_new_closed
from {{ ref('fct_opportunities') }} o
join {{ ref('dim_sales_reps') }} r on r.rep_id = o.rep_id
join {{ ref('dim_accounts') }} a on a.account_id = o.account_id
where not a.is_internal
