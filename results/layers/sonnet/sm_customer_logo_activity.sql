{{ config(materialized='table', schema='marts') }}

-- Account-level, month-end grain derived from fct_subscription_months, used to power
-- logo-based metrics (new customers, logo churn, logo churn rate) that need to compare
-- an account's paying status this month against its own history. Internal/QA accounts
-- (dim_accounts.is_internal) are excluded so they never count as real logos.
with account_month as (
    select
        sm.account_id,
        sm.month_end,
        bool_or(sm.status in ('active', 'past_due')) as is_paying_customer
    from {{ ref('fct_subscription_months') }} sm
    inner join {{ ref('dim_accounts') }} a on a.account_id = sm.account_id
    where not a.is_internal
    group by 1, 2
),
with_history as (
    select
        account_id,
        month_end,
        is_paying_customer,
        lag(is_paying_customer) over (partition by account_id order by month_end) as was_paying_prior_month,
        min(case when is_paying_customer then month_end end)
            over (partition by account_id) as first_paying_month
    from account_month
)
select
    account_id,
    month_end,
    is_paying_customer,
    coalesce(was_paying_prior_month, false) as was_paying_prior_month,
    is_paying_customer and month_end = first_paying_month as is_new_customer,
    coalesce(was_paying_prior_month, false) and not is_paying_customer as is_churned_logo
from with_history
