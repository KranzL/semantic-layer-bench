{{
    config(
        materialized = 'table',
        schema = 'marts'
    )
}}

with months as (
    select distinct month_end
    from {{ ref('fct_subscription_months') }}
),
eligible_accounts as (
    select account_id
    from {{ ref('dim_accounts') }}
    where not is_internal and not is_deleted
),
paying_mrr as (
    select
        sm.account_id,
        sm.month_end,
        sum(
            sm.seats * sm.unit_price_minor * (1 - sm.discount_pct)
            / case when sm.billing_interval = 'year' then 12 else 1 end
            / power(10, sm.minor_unit_exponent) * sm.usd_per_unit
        ) as mrr_usd
    from {{ ref('fct_subscription_months') }} sm
    join eligible_accounts a on a.account_id = sm.account_id
    where sm.status in ('active', 'past_due')
    group by sm.account_id, sm.month_end
),
grid as (
    select
        a.account_id,
        m.month_end,
        coalesce(p.mrr_usd, 0) as mrr_usd,
        p.mrr_usd is not null as is_paying
    from eligible_accounts a
    cross join months m
    left join paying_mrr p
        on p.account_id = a.account_id and p.month_end = m.month_end
),
flagged as (
    select
        account_id,
        month_end,
        mrr_usd,
        is_paying,
        lag(is_paying) over (partition by account_id order by month_end) as prev_is_paying,
        min(case when is_paying then month_end end) over (partition by account_id) as first_paying_month
    from grid
)
select
    account_id || '_' || cast(month_end as varchar) as account_month_id,
    account_id,
    month_end,
    mrr_usd,
    is_paying,
    coalesce(prev_is_paying, false) as prev_is_paying,
    coalesce(prev_is_paying, false) and not is_paying as is_churned,
    first_paying_month,
    coalesce(month_end = first_paying_month, false) as is_new
from flagged
