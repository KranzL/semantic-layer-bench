{{ config(materialized='table', schema='semantic') }}

-- One row per sales opportunity with the owning rep's team and the customer
-- (top-level account). Amounts are already in USD in the source.
-- stage is open, closed_won or closed_lost. opportunity_type is 'new'
-- (first purchase by an account) or 'expansion' (additional business on an
-- existing account). Bookings are the amount of closed_won opportunities,
-- dated by close_date. Win rate only considers closed opportunities.
-- No opportunities exist for internal accounts, but they are filtered anyway.
with opps as (
    select * from {{ ref('fct_opportunities') }}
),
accounts as (
    select
        account_id,
        coalesce(parent_account_id, account_id) as customer_id,
        is_internal
    from {{ ref('dim_accounts') }}
),
reps as (
    select rep_id, team, region as rep_region from {{ ref('dim_sales_reps') }}
)
select
    o.opportunity_id,
    o.account_id,
    a.customer_id,
    o.rep_id,
    r.team                                               as sales_team,
    r.rep_region,
    o.opportunity_type,
    o.stage,
    o.created_date,
    o.close_date,
    datediff('day', o.created_date, o.close_date)        as days_to_close,
    o.amount_usd,
    o.stage = 'closed_won'                               as is_won,
    o.stage = 'closed_lost'                              as is_lost,
    o.stage in ('closed_won', 'closed_lost')             as is_closed,
    o.stage = 'open'                                     as is_open,
    o.opportunity_type = 'new'                           as is_new_business,
    case when o.stage = 'closed_won' then o.amount_usd else 0 end                                    as booking_usd,
    case when o.stage = 'closed_won' and o.opportunity_type = 'new' then o.amount_usd else 0 end       as new_booking_usd,
    case when o.stage = 'closed_won' and o.opportunity_type = 'expansion' then o.amount_usd else 0 end as expansion_booking_usd,
    case when o.stage = 'open' then o.amount_usd else 0 end                                          as open_pipeline_usd
from opps o
join accounts a on a.account_id = o.account_id
left join reps r on r.rep_id = o.rep_id
where not a.is_internal
