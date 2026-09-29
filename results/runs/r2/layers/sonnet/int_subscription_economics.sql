{{ config(materialized='table', schema='marts') }}

-- One row per subscription per month-end snapshot (mirrors fct_subscription_months' grain).
-- Adds mrr_amount_usd: the seat fees for that snapshot, net of the line discount, converted
-- to USD at the month-end fx rate, and normalized to a monthly amount (annual plans / 12).
-- Internal/test accounts (dim_accounts.is_internal) are dropped here so every downstream
-- MRR/ARR metric is automatically customer-only.
select
    sm.subscription_id,
    sm.account_id,
    sm.plan_id,
    sm.month_end,
    sm.status,
    sm.seats,
    sm.seats
        * sm.unit_price_minor
        * (1 - sm.discount_pct)
        / power(10, sm.minor_unit_exponent)
        * sm.usd_per_unit
        / case when sm.billing_interval = 'year' then 12.0 else 1.0 end
        as mrr_amount_usd
from {{ ref('fct_subscription_months') }} sm
join {{ ref('dim_accounts') }} a on a.account_id = sm.account_id
where not a.is_internal
