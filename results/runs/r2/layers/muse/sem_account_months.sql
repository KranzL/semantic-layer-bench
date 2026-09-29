with monthly as (
    select
        month_end,
        account_id,
        max(account_name) as account_name,
        max(segment) as segment,
        max(region) as region,
        max(country) as country,
        max(billing_currency) as billing_currency,
        max(parent_account_id) as parent_account_id,
        max(case when status in ('active', 'past_due') then 1 else 0 end) as is_paying_int,
        sum(mrr_usd) as mrr_usd
    from {{ ref('sem_subscription_months') }}
    group by month_end, account_id
),
lagged as (
    select
        m.*,
        coalesce(lag(is_paying_int) over (partition by account_id order by month_end), 0) as was_paying_int,
        min(case when is_paying_int = 1 then month_end end) over (partition by account_id) as first_paying_month
    from monthly m
)
select
    account_id || '|' || cast(month_end as varchar) as row_key,
    month_end,
    account_id,
    account_name,
    segment,
    region,
    country,
    billing_currency,
    parent_account_id,
    mrr_usd,
    is_paying_int = 1 as is_paying,
    coalesce(was_paying_int, 0) = 1 as was_paying,
    (is_paying_int = 1 and month_end = first_paying_month) as is_new_customer,
    (coalesce(was_paying_int, 0) = 1 and is_paying_int = 0) as is_churned,
    case when is_paying_int = 1 then account_id end as paying_account_id,
    case when is_paying_int = 1 and month_end = first_paying_month then account_id end as new_account_id,
    case when coalesce(was_paying_int, 0) = 1 and is_paying_int = 0 then account_id end as churned_account_id,
    case when coalesce(was_paying_int, 0) = 1 then account_id end as prior_paying_account_id
from lagged
