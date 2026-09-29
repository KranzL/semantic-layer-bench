select
    o.opportunity_id as row_key,
    o.close_date,
    o.created_date,
    o.opportunity_id,
    o.opportunity_type,
    o.stage as opportunity_stage,
    o.rep_id,
    r.rep_name as sales_rep,
    r.team as sales_team,
    r.region as sales_region,
    o.account_id,
    a.account_name,
    a.segment,
    a.region,
    a.country,
    a.billing_currency,
    o.amount_usd,
    case when o.stage = 'closed_won' then o.amount_usd else 0 end as booked_usd,
    case when o.stage = 'closed_won' and o.opportunity_type = 'new' then o.amount_usd else 0 end as new_booked_usd,
    case when o.stage = 'closed_won' and o.opportunity_type = 'expansion' then o.amount_usd else 0 end as expansion_booked_usd,
    case when o.stage in ('closed_won', 'closed_lost') then o.amount_usd else 0 end as closed_usd,
    case when o.stage = 'open' then o.amount_usd else 0 end as open_usd,
    case when o.stage = 'closed_won' then o.opportunity_id end as won_opp_id,
    case when o.stage in ('closed_won', 'closed_lost') then o.opportunity_id end as closed_opp_id,
    case when o.stage = 'open' then o.opportunity_id end as open_opp_id
from {{ ref('fct_opportunities') }} o
join {{ ref('dim_sales_reps') }} r on r.rep_id = o.rep_id
join {{ ref('dim_accounts') }} a on a.account_id = o.account_id
where not a.is_internal and not a.is_deleted
