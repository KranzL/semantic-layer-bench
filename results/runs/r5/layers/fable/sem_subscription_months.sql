{{ config(materialized='table', schema='semantic') }}

-- One row per subscription per month-end on which the subscription was active
-- (paying). Trialing, past_due and canceled month-ends are removed, as are
-- internal and soft-deleted accounts. MRR is normalised to a monthly amount in
-- USD at the month-end FX rate.
select
    f.subscription_id || '|' || cast(f.month_end as varchar) as subscription_month_id,
    f.subscription_id,
    f.account_id,
    a.customer_id,
    f.plan_id,
    cast(date_trunc('month', f.month_end) as date) as month_start,
    f.month_end,
    f.billing_interval,
    f.currency,
    f.seats,
    f.discount_pct,
    f.discount_pct > 0 as is_discounted,
    f.seats * f.unit_price_minor * (1 - f.discount_pct)
        / case when f.billing_interval = 'year' then 12 else 1 end
        / power(10, f.minor_unit_exponent)
        * f.usd_per_unit as mrr_usd
from {{ ref('fct_subscription_months') }} f
join {{ ref('sem_accounts') }} a on a.account_id = f.account_id
where f.status = 'active'
