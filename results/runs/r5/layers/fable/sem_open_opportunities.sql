{{ config(materialized='table', schema='semantic') }}

-- One row per sales opportunity that is still open, on a real account
-- (internal and soft-deleted accounts removed). close_date is the expected
-- close date and can be in the past (overdue) or the future.
select
    o.opportunity_id,
    o.account_id,
    a.customer_id,
    o.rep_id,
    o.opportunity_type,
    o.created_date,
    o.close_date as expected_close_date,
    o.amount_usd
from {{ ref('fct_opportunities') }} o
join {{ ref('sem_accounts') }} a on a.account_id = o.account_id
where o.stage = 'open'
