{{ config(materialized='table', schema='marts') }}

-- One row per subscription per calendar month-end on which the subscription
-- contributes recurring revenue. Only external (non-internal, non-deleted)
-- accounts, and only versions in status active or past_due (trialing and
-- canceled versions carry no MRR).
-- MRR = seats * per-seat list price * (1 - discount), normalised to one month
-- (annual prices / 12), converted from minor units and to USD at the
-- month-end FX rate.
select
    f.subscription_id || '|' || cast(f.month_end as varchar) as subscription_month_id,
    f.subscription_id,
    f.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    f.plan_id,
    f.month_end,
    f.status,
    f.billing_interval,
    f.currency,
    f.seats,
    f.discount_pct,
    f.seats * f.unit_price_minor * (1 - f.discount_pct)
        / power(10, f.minor_unit_exponent)
        / case when f.billing_interval = 'year' then 12 else 1 end as mrr_local,
    f.seats * f.unit_price_minor * (1 - f.discount_pct)
        / power(10, f.minor_unit_exponent)
        / case when f.billing_interval = 'year' then 12 else 1 end
        * f.usd_per_unit as mrr_usd
from {{ ref('fct_subscription_months') }} f
join {{ ref('dim_accounts') }} a on a.account_id = f.account_id
where f.status in ('active', 'past_due')
  and not a.is_internal
  and not a.is_deleted
