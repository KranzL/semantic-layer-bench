-- Month-end MRR snapshot: one row per paying subscription per calendar month.
-- Paying = subscription version status 'active' or 'past_due' on the month-end date
-- (trialing and canceled versions carry no MRR). Internal accounts are excluded.
-- MRR = seats * unit price * (1 - discount), annual plans divided by 12, converted from
-- minor units to major units and then to USD at the month-end FX rate. Excludes tax.
select
    m.subscription_id || '-' || strftime(m.month_end, '%Y%m') as subscription_month_id,
    m.subscription_id,
    m.account_id,
    a.customer_id,
    m.plan_id,
    cast(date_trunc('month', m.month_end) as date) as month_start,
    m.month_end,
    d.fiscal_year,
    'FY' || d.fiscal_year || ' Q' || d.fiscal_quarter as fiscal_quarter,
    m.status,
    m.billing_interval,
    m.currency,
    m.seats,
    m.seats * m.unit_price_minor * (1 - m.discount_pct)
        / power(10, m.minor_unit_exponent)
        / case when m.billing_interval = 'year' then 12 else 1 end as mrr_local,
    m.seats * m.unit_price_minor * (1 - m.discount_pct)
        / power(10, m.minor_unit_exponent)
        / case when m.billing_interval = 'year' then 12 else 1 end
        * m.usd_per_unit as mrr_usd
from {{ ref('fct_subscription_months') }} m
join {{ ref('sem_accounts') }} a on a.account_id = m.account_id
join {{ ref('dim_date') }} d on d.date_day = m.month_end
where m.status in ('active', 'past_due')
