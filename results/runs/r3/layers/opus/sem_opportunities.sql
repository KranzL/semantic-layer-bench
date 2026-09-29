-- Sales opportunities for external accounts with the owning rep's team.
-- amount_usd is the contract value in USD recorded on the opportunity.
select
    o.opportunity_id,
    o.account_id,
    a.customer_id,
    o.rep_id,
    o.opportunity_type,
    o.stage,
    o.created_date,
    o.close_date,
    d.fiscal_year,
    'FY' || d.fiscal_year || ' Q' || d.fiscal_quarter as fiscal_quarter,
    o.amount_usd
from {{ ref('fct_opportunities') }} o
join {{ ref('sem_accounts') }} a on a.account_id = o.account_id
join {{ ref('dim_date') }} d on d.date_day = o.close_date
