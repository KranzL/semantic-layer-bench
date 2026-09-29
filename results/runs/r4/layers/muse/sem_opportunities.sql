{{ config(materialized='table', schema='marts') }}

select
    o.opportunity_id,
    o.account_id,
    o.rep_id,
    o.opportunity_type,
    o.stage,
    o.created_date,
    o.close_date,
    o.amount_usd,
    o.stage = 'closed_won' as is_won,
    o.stage = 'closed_lost' as is_lost,
    o.stage in ('closed_won', 'closed_lost') as is_closed,
    o.stage = 'open' as is_open,
    case when o.stage = 'closed_won' then o.amount_usd else 0 end as bookings_usd,
    case when o.stage = 'closed_won' and o.opportunity_type = 'new' then o.amount_usd else 0 end as new_bookings_usd,
    case when o.stage = 'closed_won' and o.opportunity_type = 'expansion' then o.amount_usd else 0 end as expansion_bookings_usd,
    case when o.stage = 'open' then o.amount_usd else 0 end as open_pipeline_usd,
    case when o.stage = 'closed_won' then 1 else 0 end as won_count,
    case when o.stage = 'closed_lost' then 1 else 0 end as lost_count,
    case when o.stage in ('closed_won', 'closed_lost') then 1 else 0 end as closed_count,
    case when o.stage = 'open' then 1 else 0 end as open_count
from {{ ref('fct_opportunities') }} o
join {{ ref('dim_accounts') }} a on a.account_id = o.account_id
where not a.is_internal and not a.is_deleted
