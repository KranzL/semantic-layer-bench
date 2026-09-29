{{ config(materialized='table', schema='semantic') }}

-- Month-end subscription snapshot for reportable accounts with MRR normalised to USD.
-- unit_price_minor is the price per seat per billing interval in the currency's minor unit,
-- so annual plans are divided by 12 and the amount is scaled by the currency's exponent
-- (JPY has no minor unit) before converting at the month-end FX rate.
select
    m.subscription_id || '|' || cast(m.month_end as varchar) as subscription_month_id,
    m.subscription_id,
    m.account_id,
    a.customer_id,
    m.plan_id,
    m.month_end,
    cast(date_trunc('month', m.month_end) as date) as snapshot_month,
    m.status,
    m.status in ('active', 'past_due') as is_paying,
    m.billing_interval,
    m.currency,
    m.discount_pct > 0 as is_discounted,
    case when m.status in ('active', 'past_due') then m.seats else 0 end as paying_seats,
    case
        when m.status in ('active', 'past_due') then
            m.seats * m.unit_price_minor * (1 - m.discount_pct)
            / power(10, m.minor_unit_exponent)
            / case when m.billing_interval = 'year' then 12 else 1 end
            * m.usd_per_unit
        else 0
    end as mrr_usd
from {{ ref('fct_subscription_months') }} m
join {{ ref('sem_accounts') }} a on a.account_id = m.account_id
