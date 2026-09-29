{{ config(materialized='table', schema='marts') }}

-- One row per account per month-end for every month from an account's first
-- subscription version onward through the latest month covered by the
-- subscription data. Used to detect month-over-month paying-status
-- transitions (new logos, churned logos) at the account grain, since a
-- single account can hold more than one subscription over time (e.g. an
-- upgrade implemented as a new subscription while the old one is canceled)
-- and subscription-level cancellation is not always account-level churn.
with account_month as (
    select
        account_id,
        month_end,
        segment,
        region,
        country,
        max(case when is_paying then 1 else 0 end) as is_paying,
        sum(case when is_paying then mrr_usd else 0 end) as mrr_usd
    from {{ ref('int_subscription_month_snapshot') }}
    group by all
),

with_history as (
    select
        *,
        lag(is_paying) over (partition by account_id order by month_end) as prior_month_is_paying,
        min(case when is_paying = 1 then month_end end) over (partition by account_id) as first_paying_month_end
    from account_month
)

select
    account_id || '-' || cast(month_end as varchar) as account_month_id,
    account_id,
    month_end,
    segment,
    region,
    country,
    is_paying = 1 as is_paying,
    mrr_usd,
    is_paying = 1 and month_end = first_paying_month_end as is_new_customer_month,
    prior_month_is_paying = 1 and is_paying = 0 as is_churned_customer_month
from with_history
