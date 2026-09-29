-- One row per external subscription per month-end snapshot (2023-01-31 to 2025-06-30).
-- MRR is in USD at the month-end FX rate: seats x unit price x (1 - discount), annual plans divided by 12.
-- Only active and past_due subscriptions are paying; trialing and canceled carry zero MRR.
select
    s.subscription_id,
    s.account_id,
    a.customer_id,
    s.month_end,
    s.status,
    s.plan_id,
    s.billing_interval,
    s.currency,
    s.status in ('active', 'past_due') as is_paying,
    case when s.status in ('active', 'past_due') then a.customer_id end as paying_customer_id,
    case
        when s.status in ('active', 'past_due')
        then s.seats * s.unit_price_minor * (1 - s.discount_pct)
             / pow(10, s.minor_unit_exponent) * s.usd_per_unit
             / case when s.billing_interval = 'year' then 12 else 1 end
        else 0
    end as mrr_usd
from {{ ref('fct_subscription_months') }} s
join {{ ref('sem_accounts') }} a on a.account_id = s.account_id
