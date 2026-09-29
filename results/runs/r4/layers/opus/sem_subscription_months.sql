{{ config(materialized='table', schema='marts') }}

-- One row per subscription per calendar month-end snapshot where the subscription is in
-- status 'active' on the month-end date. Trialing, past_due and canceled versions are
-- excluded, as are subscriptions of internal/test accounts (accounts.is_internal).
-- MRR is net of the contractual discount, excludes tax, normalises annual plans to /12 and
-- is converted to USD at the month-end FX rate.
select
    f.subscription_id || '|' || cast(f.month_end as varchar) as subscription_month_id,
    f.subscription_id,
    f.account_id,
    f.plan_id,
    cast(date_trunc('month', f.month_end) as date) as month_start,
    f.month_end,
    f.billing_interval,
    f.currency,
    f.seats,
    f.discount_pct,
    f.seats * f.unit_price_minor * (1 - f.discount_pct)
        / case when f.billing_interval = 'year' then 12 else 1 end
        / power(10, f.minor_unit_exponent) as mrr_local,
    f.seats * f.unit_price_minor * (1 - f.discount_pct)
        / case when f.billing_interval = 'year' then 12 else 1 end
        / power(10, f.minor_unit_exponent)
        * f.usd_per_unit as mrr_usd
from {{ ref('fct_subscription_months') }} f
join {{ ref('dim_accounts') }} a on a.account_id = f.account_id
where f.status = 'active'
  and not a.is_internal
