with months as (
    select distinct month_end
    from {{ ref('fct_subscription_months') }}
),
real_accounts as (
    select account_id
    from {{ ref('dim_accounts') }}
    where not is_internal and not is_deleted
),
subs as (
    select
        s.subscription_id,
        s.account_id,
        s.month_end,
        s.status,
        s.plan_id,
        s.billing_interval,
        s.seats,
        s.currency,
        case
            when s.status in ('active', 'past_due')
            then
                s.seats * s.unit_price_minor * (1 - s.discount_pct)
                / power(10, s.minor_unit_exponent) * s.usd_per_unit
                / case when s.billing_interval = 'year' then 12.0 else 1.0 end
            else 0
        end as mrr_usd,
        s.status in ('active', 'past_due') as is_paying
    from {{ ref('fct_subscription_months') }} s
    join real_accounts a on a.account_id = s.account_id
),
account_month as (
    select
        a.account_id,
        m.month_end,
        coalesce(max(case when s.is_paying then 1 else 0 end), 0) = 1 as is_paying
    from real_accounts a
    cross join months m
    left join subs s on s.account_id = a.account_id and s.month_end = m.month_end
    group by 1, 2
),
flagged as (
    select
        account_id,
        month_end,
        is_paying,
        coalesce(lag(is_paying) over w, false) as was_paying_prev_month,
        (
            is_paying
            and coalesce(
                max(case when is_paying then 1 else 0 end) over (
                    partition by account_id order by month_end
                    rows between unbounded preceding and 1 preceding
                ),
                0
            ) = 0
        ) as is_new_customer,
        (not is_paying and coalesce(lag(is_paying) over w, false)) as is_churned
    from account_month
    window w as (partition by account_id order by month_end)
)
select
    f.account_id,
    f.month_end,
    s.subscription_id,
    s.status,
    s.plan_id,
    s.billing_interval,
    s.seats,
    s.currency,
    coalesce(s.mrr_usd, 0) as mrr_usd,
    f.is_paying,
    f.was_paying_prev_month,
    f.is_new_customer,
    f.is_churned
from flagged f
left join subs s on s.account_id = f.account_id and s.month_end = f.month_end
