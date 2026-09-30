{{ config(materialized='table', schema='marts') }}

-- Month-end MRR snapshot, one row per live subscription per month-end.
-- Live = status active or past_due. Trialing and canceled versions are excluded, as are internal/QA accounts.
-- Customer = parent account when one exists, otherwise the account itself.
select
    sm.subscription_id,
    sm.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    sm.month_end,
    sm.plan_id,
    p.plan_name,
    p.plan_family,
    sm.billing_interval,
    sm.currency,
    ca.segment,
    ca.region,
    ca.country,
    sm.seats,
    sm.seats * sm.unit_price_minor * (1 - sm.discount_pct)
        / case when sm.billing_interval = 'year' then 12.0 else 1.0 end
        / power(10, sm.minor_unit_exponent) * sm.usd_per_unit as mrr_usd
from {{ ref('fct_subscription_months') }} sm
join {{ ref('dim_accounts') }} a on a.account_id = sm.account_id
join {{ ref('dim_accounts') }} ca on ca.account_id = coalesce(a.parent_account_id, a.account_id)
join {{ ref('dim_plans') }} p on p.plan_id = sm.plan_id
where sm.status in ('active', 'past_due')
  and not a.is_internal
