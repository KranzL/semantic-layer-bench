-- One row per sales opportunity on an external (non-internal) account, all stages.
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
    f.fiscal_year as close_fiscal_year,
    f.fiscal_quarter as close_fiscal_quarter,
    o.amount_usd
from {{ ref('fct_opportunities') }} o
join {{ ref('sem_accounts') }} a on a.account_id = o.account_id
join {{ ref('sem_fiscal_time_spine') }} f on f.date_day = o.close_date
