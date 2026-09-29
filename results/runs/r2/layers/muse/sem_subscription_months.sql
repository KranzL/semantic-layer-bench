with base as (
    select
        s.subscription_id,
        s.account_id,
        s.month_end,
        s.status,
        s.plan_id,
        s.billing_interval,
        s.seats,
        s.discount_pct,
        s.currency,
        s.seats * s.unit_price_minor * (1 - s.discount_pct)
            / case when s.billing_interval = 'year' then 12.0 else 1.0 end
            / power(10, s.minor_unit_exponent) * s.usd_per_unit as mrr_usd_raw,
        a.account_name,
        a.segment,
        a.region,
        a.country,
        a.billing_currency,
        a.parent_account_id
    from {{ ref('fct_subscription_months') }} s
    join {{ ref('dim_accounts') }} a on a.account_id = s.account_id
    where not a.is_internal and not a.is_deleted
)
select
    b.subscription_id || '|' || cast(b.month_end as varchar) as row_key,
    b.month_end,
    b.subscription_id,
    b.account_id,
    b.account_name,
    b.segment,
    b.region,
    b.country,
    b.billing_currency,
    b.parent_account_id,
    b.status,
    b.plan_id,
    p.plan_name,
    p.plan_family,
    b.billing_interval,
    b.seats,
    b.discount_pct,
    b.currency,
    case when b.status in ('active', 'past_due') then b.mrr_usd_raw else 0 end as mrr_usd
from base b
join {{ ref('dim_plans') }} p on p.plan_id = b.plan_id
