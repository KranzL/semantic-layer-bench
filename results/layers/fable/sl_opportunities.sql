{{ config(materialized='table', schema='semantic') }}

-- One row per CRM opportunity, for reportable accounts only (internal and soft-deleted
-- accounts excluded; in practice no opportunity is attached to one). Amounts are already
-- in USD in the source. Types: 'new' (first sale to an account) and 'expansion'.
-- Stages: 'open', 'closed_won', 'closed_lost'. close_date is the actual close date for
-- closed opportunities and the expected close date for open ones (may be in the future).
with opp as (
    select * from {{ ref('fct_opportunities') }}
),
accounts as (
    select * from {{ ref('sl_accounts') }} where is_reportable
)
select
    o.opportunity_id,
    o.account_id,
    a.customer_id,
    o.rep_id,
    o.opportunity_type,
    o.stage,
    o.stage = 'closed_won' as is_won,
    o.stage = 'closed_lost' as is_lost,
    o.stage in ('closed_won', 'closed_lost') as is_closed,
    o.stage = 'open' as is_open,
    o.created_date,
    o.close_date,
    datediff('day', o.created_date, o.close_date) as days_to_close,
    o.amount_usd,
    case when o.stage = 'closed_won' then o.amount_usd else 0 end as won_amount_usd,
    case when o.stage = 'closed_won' and o.opportunity_type = 'new' then o.amount_usd else 0 end as new_won_amount_usd,
    case when o.stage = 'closed_won' and o.opportunity_type = 'expansion' then o.amount_usd else 0 end as expansion_won_amount_usd,
    case when o.stage = 'open' then o.amount_usd else 0 end as open_amount_usd
from opp o
join accounts a on a.account_id = o.account_id
