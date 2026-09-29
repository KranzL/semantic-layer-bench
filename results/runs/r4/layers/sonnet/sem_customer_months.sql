{{ config(materialized='table') }}
-- Month-end subscription snapshot for external customers (child accounts roll up to their parent).
-- Two kinds of rows share this table:
--   * paying rows: one per paying subscription per month-end (status active or past_due), carrying MRR in USD.
--     The customer's largest-MRR subscription that month also carries the customer-level flags.
--   * opening rows: one per customer paying at the previous month-end, dated at the next month-end, carrying the
--     opening-customer flag (and the churn flag when the customer is not paying at that month-end). They take the
--     plan and currency the customer had at the previous month-end and carry no MRR.
with last_month as (
    select max(month_end) as month_end from {{ ref('fct_subscription_months') }}
),
paying as (
    select
        sm.subscription_id,
        coalesce(a.parent_account_id, a.account_id) as customer_id,
        sm.month_end,
        sm.plan_id,
        p.plan_name,
        p.plan_family,
        sm.billing_interval,
        sm.currency,
        sm.seats * sm.unit_price_minor * (1 - sm.discount_pct)
            / case when sm.billing_interval = 'year' then 12.0 else 1.0 end
            / power(10, sm.minor_unit_exponent) * sm.usd_per_unit as mrr_usd
    from {{ ref('fct_subscription_months') }} sm
    join {{ ref('dim_accounts') }} a on a.account_id = sm.account_id
    join {{ ref('dim_plans') }} p on p.plan_id = sm.plan_id
    where sm.status in ('active', 'past_due')
      and not a.is_internal
),
ranked as (
    select
        *,
        row_number() over (partition by customer_id, month_end order by mrr_usd desc, subscription_id) as rn,
        min(month_end) over (partition by customer_id) as first_paying_month
    from paying
),
paying_rows as (
    select
        subscription_id || '|' || cast(month_end as varchar) as row_key,
        customer_id, subscription_id, month_end, plan_id, plan_name, plan_family, billing_interval, currency,
        mrr_usd,
        case when rn = 1 then 1 else 0 end as paying_customer,
        case when rn = 1 and month_end = first_paying_month then 1 else 0 end as new_customer,
        0 as opening_customer,
        0 as churned_customer
    from ranked
),
opening_rows as (
    select
        'open|' || r.customer_id || '|' || cast(n.next_month_end as varchar) as row_key,
        r.customer_id, cast(null as varchar) as subscription_id, n.next_month_end as month_end,
        r.plan_id, r.plan_name, r.plan_family, r.billing_interval, r.currency,
        0.0 as mrr_usd,
        0 as paying_customer,
        0 as new_customer,
        1 as opening_customer,
        case when exists (
            select 1 from ranked x where x.customer_id = r.customer_id and x.month_end = n.next_month_end
        ) then 0 else 1 end as churned_customer
    from ranked r
    cross join lateral (select cast(last_day(r.month_end + interval 1 month) as date) as next_month_end) n
    where r.rn = 1
      and n.next_month_end <= (select month_end from last_month)
)
select * from paying_rows
union all
select * from opening_rows
