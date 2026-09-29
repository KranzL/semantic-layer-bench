{{ config(materialized='table', schema='marts') }}

-- One row per non-internal account per calendar month-end in the observed subscription
-- window (2023-01-31 through 2025-06-30, matching fct_subscription_months). Every account
-- gets a row for every month, even months with no subscription activity, so that
-- month-over-month comparisons (new logo / churned logo) are correct instead of only being
-- computed over sparse subscription rows.
--
-- is_paying: the account has at least one subscription version with status 'active' or
-- 'past_due' effective at that month end (see int_subscription_economics for the same
-- paying-status definition used for MRR).
--
-- was_paying_prior_month / is_new_logo / is_churned_logo compare each month to the
-- immediately preceding calendar month for the same account. Because the very first month
-- in the window (2023-01-31) has no prior month to compare against, its
-- was_paying_prior_month, is_new_logo and is_churned_logo values are all null (neither new
-- nor churned by construction) rather than being guessed.
with month_ends as (
    select date_day as month_end
    from {{ ref('dim_date') }}
    where is_month_end and date_day between date '2023-01-31' and date '2025-06-30'
),

accounts as (
    select account_id from {{ ref('dim_accounts') }} where not is_internal
),

account_months as (
    select a.account_id, m.month_end
    from accounts a
    cross join month_ends m
),

paying_subscriptions as (
    select distinct account_id, month_end
    from {{ ref('fct_subscription_months') }}
    where status in ('active', 'past_due')
),

flagged as (
    select
        am.account_id,
        am.month_end,
        ps.account_id is not null as is_paying
    from account_months am
    left join paying_subscriptions ps
        on ps.account_id = am.account_id
        and ps.month_end = am.month_end
)

select
    account_id,
    month_end,
    is_paying,
    lag(is_paying) over (partition by account_id order by month_end) as was_paying_prior_month,
    is_paying and not lag(is_paying) over (partition by account_id order by month_end) as is_new_logo,
    not is_paying and lag(is_paying) over (partition by account_id order by month_end) as is_churned_logo
from flagged
