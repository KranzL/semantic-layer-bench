-- Opportunities of external accounts with the close outcome. Open opportunities have a future expected close_date
-- and are excluded, so every row here is closed_won or closed_lost and dated by its actual close date.
select
    o.opportunity_id,
    o.account_id,
    a.customer_id,
    o.rep_id,
    o.opportunity_type,
    o.stage,
    o.close_date,
    o.stage = 'closed_won' as is_won,
    o.amount_usd,
    case when o.stage = 'closed_won' then o.amount_usd else 0 end as won_amount_usd
from {{ ref('fct_opportunities') }} o
join {{ ref('sem_accounts') }} a on a.account_id = o.account_id
where o.stage in ('closed_won', 'closed_lost')
