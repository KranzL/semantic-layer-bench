with paying as (
    select m.account_id, m.month_end, bool_or(m.status in ('active', 'past_due')) as is_paying
    from {{ ref('fct_subscription_months') }} m
    join {{ ref('dim_accounts') }} a on a.account_id = m.account_id
    where not a.is_internal and not a.is_deleted
    group by all
),
grid as (
    select a.account_id, d.date_day as month_end
    from (select distinct account_id from paying) a
    cross join {{ ref('dim_date') }} d
    where d.is_month_end and d.date_day between date '2023-01-31' and date '2025-06-30'
),
flags as (
    select g.account_id, g.month_end, coalesce(p.is_paying, false) as is_paying
    from grid g
    left join paying p on p.account_id = g.account_id and p.month_end = g.month_end
)
select
    account_id,
    month_end,
    is_paying,
    coalesce(lag(is_paying) over (partition by account_id order by month_end), false) as was_paying_prior_month_end,
    is_paying and not coalesce(bool_or(is_paying) over (partition by account_id order by month_end rows between unbounded preceding and 1 preceding), false) as is_new_customer
from flags
