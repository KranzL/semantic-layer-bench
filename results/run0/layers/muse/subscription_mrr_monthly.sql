{{
    config(
        materialized='table',
        schema='marts'
    )
}}

with monthly as (
    select
        sm.subscription_id,
        sm.account_id,
        sm.month_end,
        sm.version_id,
        sm.status,
        sm.plan_id,
        sm.billing_interval,
        sm.seats,
        sm.unit_price_minor,
        sm.discount_pct,
        sm.currency,
        sm.minor_unit_exponent,
        sm.usd_per_unit,
        case when sm.status in ('active', 'past_due') then 1 else 0 end as is_paying,
        case
            when sm.status in ('active', 'past_due')
            then
                sm.seats * sm.unit_price_minor * (1 - sm.discount_pct)
                / power(10, sm.minor_unit_exponent) * sm.usd_per_unit
                / case when sm.billing_interval = 'year' then 12 else 1 end
            else 0
        end as mrr_usd
    from {{ ref('fct_subscription_months') }} sm
),
account_month as (
    select
        account_id,
        month_end,
        max(is_paying) as account_is_paying
    from monthly
    group by account_id, month_end
),
account_flags as (
    select
        account_id,
        month_end,
        account_is_paying,
        lag(account_is_paying) over (partition by account_id order by month_end) as prev_month_paying,
        min(case when account_is_paying = 1 then month_end end) over (partition by account_id) as first_paying_month
    from account_month
),
joined as (
    select
        m.subscription_id,
        m.account_id,
        m.month_end,
        m.version_id,
        m.status,
        m.plan_id,
        m.billing_interval,
        m.seats,
        m.unit_price_minor,
        m.discount_pct,
        m.currency,
        m.minor_unit_exponent,
        m.usd_per_unit,
        m.is_paying,
        m.mrr_usd,
        af.account_is_paying,
        coalesce(af.prev_month_paying, 0) as prev_month_paying,
        case when af.account_is_paying = 1 and af.month_end = af.first_paying_month then 1 else 0 end as account_is_new,
        case when coalesce(af.prev_month_paying, 0) = 1 and af.account_is_paying = 0 then 1 else 0 end as account_is_churned,
        row_number() over (partition by m.account_id, m.month_end order by m.subscription_id) as rank_in_account_month
    from monthly m
    join account_flags af on af.account_id = m.account_id and af.month_end = m.month_end
)
select
    subscription_id,
    account_id,
    month_end,
    version_id,
    status,
    plan_id,
    billing_interval,
    seats,
    unit_price_minor,
    discount_pct,
    currency,
    minor_unit_exponent,
    usd_per_unit,
    is_paying,
    mrr_usd,
    case when rank_in_account_month = 1 then account_is_paying else 0 end as paying_account_flag,
    case when rank_in_account_month = 1 then account_is_new else 0 end as new_customer_flag,
    case when rank_in_account_month = 1 then account_is_churned else 0 end as churned_customer_flag,
    case when rank_in_account_month = 1 then prev_month_paying else 0 end as prev_month_paying_flag
from joined
