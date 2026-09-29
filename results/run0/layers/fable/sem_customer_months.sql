{{ config(materialized='table', schema='semantic') }}

-- One row per customer (logo) per month_end, from the customer's first paying
-- month through the last month in the warehouse, so that a customer who stops
-- paying still has a row in the month they churn.
-- Built from sem_subscription_months, so internal accounts are already excluded
-- and child accounts are rolled up to their parent.
-- Lifecycle flags:
--   is_new         first month the customer ever had MRR
--   is_churned     paid last month, has no MRR this month (logo churn)
--   is_reactivated has MRR this month after one or more months without MRR,
--                  and is not new
--   is_retained    paid both this month and last month
-- MRR bridge (USD): expansion / contraction / churned MRR compare this month
-- against last month with BOTH months valued at this month's FX rate, so FX
-- swings do not appear as expansion or contraction. The FX effect is isolated
-- in fx_impact_mrr_usd. new + expansion + reactivation - contraction - churned
-- + fx_impact = mrr_usd - prev_mrr_usd exactly.
with spine as (
    select date_day as month_end
    from {{ ref('dim_date') }}
    where is_month_end
      and date_day between date '2023-01-31' and date '2025-06-30'
),
sub_months as (
    select * from {{ ref('sem_subscription_months') }}
),
-- MRR per customer, month and currency in local units
by_currency as (
    select customer_id, month_end, currency, sum(mrr_local) as mrr_local
    from sub_months
    group by 1, 2, 3
),
customer_currencies as (
    select distinct customer_id, currency from by_currency
),
firsts as (
    select
        customer_id,
        min(case when mrr_local > 0 then month_end end) as first_paying_month
    from by_currency
    group by 1
    having min(case when mrr_local > 0 then month_end end) is not null
),
grid as (
    select f.customer_id, cc.currency, s.month_end, f.first_paying_month
    from firsts f
    join customer_currencies cc on cc.customer_id = f.customer_id
    join spine s on s.month_end >= f.first_paying_month
),
filled as (
    select
        g.customer_id,
        g.currency,
        g.month_end,
        g.first_paying_month,
        coalesce(bc.mrr_local, 0) as mrr_local,
        fx.usd_per_unit
    from grid g
    left join by_currency bc
      on bc.customer_id = g.customer_id and bc.currency = g.currency and bc.month_end = g.month_end
    join {{ ref('stg_fx_rates') }} fx
      on fx.currency = g.currency and fx.rate_date = g.month_end
),
lagged as (
    select
        *,
        lag(mrr_local)    over (partition by customer_id, currency order by month_end) as prev_mrr_local,
        lag(usd_per_unit) over (partition by customer_id, currency order by month_end) as prev_usd_per_unit
    from filled
),
per_customer as (
    select
        customer_id,
        month_end,
        first_paying_month,
        sum(mrr_local * usd_per_unit)                             as mrr_usd,
        sum(coalesce(prev_mrr_local, 0) * coalesce(prev_usd_per_unit, usd_per_unit)) as prev_mrr_usd,
        -- last month's MRR revalued at this month's FX rate
        sum(coalesce(prev_mrr_local, 0) * usd_per_unit)           as prev_mrr_usd_constant_fx
    from lagged
    group by 1, 2, 3
),
counts as (
    select
        customer_id,
        month_end,
        count(distinct case when is_paying then account_id end)      as paying_accounts,
        count(distinct case when is_paying then subscription_id end) as paying_subscriptions,
        sum(paying_seats)                                            as paying_seats,
        count(distinct case when is_trialing then subscription_id end) as trialing_subscriptions
    from sub_months
    group by 1, 2
),
classified as (
    select
        pc.customer_id,
        pc.month_end,
        pc.first_paying_month,
        pc.mrr_usd,
        pc.prev_mrr_usd,
        pc.prev_mrr_usd_constant_fx,
        coalesce(c.paying_accounts, 0)         as paying_accounts,
        coalesce(c.paying_subscriptions, 0)    as paying_subscriptions,
        coalesce(c.paying_seats, 0)            as paying_seats,
        coalesce(c.trialing_subscriptions, 0)  as trialing_subscriptions,
        pc.mrr_usd > 0                         as is_paying,
        pc.prev_mrr_usd > 0                    as was_paying_prev_month,
        pc.month_end = pc.first_paying_month   as is_new
    from per_customer pc
    left join counts c on c.customer_id = pc.customer_id and c.month_end = pc.month_end
),
flagged as (
    select
        *,
        is_paying and not was_paying_prev_month and not is_new as is_reactivated,
        not is_paying and was_paying_prev_month                as is_churned,
        is_paying and was_paying_prev_month                    as is_retained,
        is_retained and mrr_usd > prev_mrr_usd_constant_fx + 0.005 as is_expansion,
        is_retained and mrr_usd < prev_mrr_usd_constant_fx - 0.005 as is_contraction
    from classified
)
select
    customer_id || '|' || cast(month_end as varchar) as customer_month_id,
    customer_id,
    month_end,
    first_paying_month,
    is_paying,
    was_paying_prev_month,
    is_new,
    is_reactivated,
    is_churned,
    is_retained,
    is_expansion,
    is_contraction,
    case
        when is_new then 'new'
        when is_reactivated then 'reactivated'
        when is_churned then 'churned'
        when is_expansion then 'expansion'
        when is_contraction then 'contraction'
        when is_retained then 'flat'
        else 'inactive'
    end as customer_status,
    paying_accounts,
    paying_subscriptions,
    paying_seats,
    trialing_subscriptions,
    mrr_usd,
    prev_mrr_usd,
    case when is_new then mrr_usd else 0 end                                        as new_mrr_usd,
    case when is_reactivated then mrr_usd else 0 end                                as reactivation_mrr_usd,
    case when is_expansion then mrr_usd - prev_mrr_usd_constant_fx else 0 end       as expansion_mrr_usd,
    case when is_contraction then prev_mrr_usd_constant_fx - mrr_usd else 0 end     as contraction_mrr_usd,
    case when is_churned then prev_mrr_usd_constant_fx else 0 end                   as churned_mrr_usd,
    -- residual of the bridge: change in prior-month MRR caused only by FX
    prev_mrr_usd_constant_fx - prev_mrr_usd                                         as fx_impact_mrr_usd
from flagged
