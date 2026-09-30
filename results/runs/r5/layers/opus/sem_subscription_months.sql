{{ config(materialized='table', schema='semantic') }}

-- One row per subscription per calendar month, describing the subscription version in effect at
-- month end. MRR = seats x unit price x (1 - discount), annual plans divided by 12, only for
-- versions in status active or past_due (trialing and canceled contribute 0).
-- Minor units are converted with the currency exponent (JPY has 0 decimals) and to USD at the
-- month-end FX rate.
select
    sm.subscription_id || '|' || cast(sm.month_end as varchar) as subscription_month_id,
    sm.subscription_id,
    sm.account_id,
    a.customer_id,
    cast(sm.month_end as date) as snapshot_date,
    sm.status as subscription_status,
    sm.plan_id,
    sm.billing_interval,
    sm.currency,
    sm.status in ('active', 'past_due') as is_paying,
    case when sm.status in ('active', 'past_due') then sm.seats else 0 end as paid_seats,
    case when sm.status in ('active', 'past_due')
        then sm.seats * sm.unit_price_minor * (1 - sm.discount_pct)
             / case when sm.billing_interval = 'year' then 12 else 1 end
             / power(10, sm.minor_unit_exponent)
        else 0 end as mrr_local,
    case when sm.status in ('active', 'past_due')
        then sm.seats * sm.unit_price_minor * (1 - sm.discount_pct)
             / case when sm.billing_interval = 'year' then 12 else 1 end
             / power(10, sm.minor_unit_exponent) * sm.usd_per_unit
        else 0 end as mrr_usd
from {{ ref('fct_subscription_months') }} sm
join {{ ref('sem_accounts') }} a on a.account_id = sm.account_id
where a.is_reportable
