{{ config(materialized='table', schema='semantic') }}

-- One row per closed sales opportunity (closed_won or closed_lost) on a real
-- account (internal and soft-deleted accounts removed). Open opportunities
-- are in sem_open_opportunities. Only closed_won opportunities are bookings.
select
    o.opportunity_id,
    o.account_id,
    a.customer_id,
    o.rep_id,
    o.opportunity_type,
    o.stage,
    o.stage = 'closed_won' as is_won,
    o.created_date,
    o.close_date,
    datediff('day', o.created_date, o.close_date) as days_to_close,
    o.amount_usd
from {{ ref('fct_opportunities') }} o
join {{ ref('sem_accounts') }} a on a.account_id = o.account_id
where o.stage in ('closed_won', 'closed_lost')
