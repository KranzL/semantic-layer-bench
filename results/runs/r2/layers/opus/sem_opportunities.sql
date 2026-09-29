{{ config(materialized='table', schema='marts') }}

-- Sales opportunities of external, non-deleted accounts. amount_usd is
-- the annualized contract value in USD. For open opportunities close_date is
-- the expected close date.
select
    o.opportunity_id,
    o.account_id,
    a.customer_id,
    o.rep_id,
    o.opportunity_type,
    o.stage,
    o.stage in ('closed_won', 'closed_lost') as is_closed,
    o.created_date,
    o.close_date,
    o.amount_usd
from {{ ref('fct_opportunities') }} o
join {{ ref('sem_accounts') }} a on a.account_id = o.account_id
where a.is_reportable
