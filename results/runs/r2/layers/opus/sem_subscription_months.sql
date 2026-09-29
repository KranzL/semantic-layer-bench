{{ config(materialized='table', schema='marts') }}

-- Month-end snapshot of every subscription version in effect on the last day
-- of each month (2023-01 to 2025-06), for external, non-deleted accounts only.
-- MRR is contracted recurring value: seats x unit price net of the version
-- discount, annual plans divided by 12, converted from the subscription
-- currency's minor units (JPY has 0 decimals) to USD at the month-end FX rate.
-- Only active and past_due versions carry MRR; trialing and canceled carry 0.
select
    sm.subscription_id || '|' || cast(sm.month_end as varchar) as subscription_month_id,
    sm.subscription_id,
    sm.account_id,
    a.customer_id,
    sm.month_end,
    sm.version_id,
    sm.status as subscription_status,
    sm.status in ('active', 'past_due') as is_paying,
    sm.plan_id,
    sm.billing_interval,
    sm.currency,
    sm.discount_pct,
    sm.seats,
    case when sm.status in ('active', 'past_due') then sm.seats else 0 end as paid_seats,
    case when sm.status in ('active', 'past_due') then
        sm.seats * sm.unit_price_minor * (1 - sm.discount_pct)
        / case when sm.billing_interval = 'year' then 12 else 1 end
        / power(10, sm.minor_unit_exponent) * sm.usd_per_unit
    else 0 end as mrr_usd
from {{ ref('fct_subscription_months') }} sm
join {{ ref('sem_accounts') }} a on a.account_id = sm.account_id
where a.is_reportable
