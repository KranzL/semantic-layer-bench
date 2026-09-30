{{ config(materialized='table', schema='marts') }}

-- Billable usage: api_call events on days the account had a live (active or past_due) subscription version.
-- health_check pings, trial-only days and internal/QA accounts are excluded.
select
    u.account_id,
    u.usage_date,
    u.event_type,
    a.segment,
    a.region,
    a.country,
    a.billing_currency,
    u.quantity
from {{ ref('fct_usage_daily') }} u
join {{ ref('dim_accounts') }} a on a.account_id = u.account_id
where u.event_type = 'api_call'
  and not a.is_internal
  and exists (
      select 1
      from {{ ref('stg_subscriptions') }} s
      join {{ ref('stg_subscription_versions') }} v on v.subscription_id = s.subscription_id
      where s.account_id = u.account_id
        and v.status in ('active', 'past_due')
        and v.valid_from <= u.usage_date
        and (v.valid_to is null or u.usage_date < v.valid_to)
  )
