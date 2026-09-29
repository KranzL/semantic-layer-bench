{{ config(materialized='table', schema='semantic') }}

-- One row per account per day per event type, excluding internal accounts,
-- with the account's subscription status on that day.
-- event_type is 'api_call' (customer-driven, metered) or 'health_check'
-- (a platform heartbeat that fires exactly 288 times a day for every account
-- and is never charged).
-- is_billable = api_call usage on a day when the account had an active or
-- past_due subscription. Usage during a free trial, after cancellation or
-- with no subscription is recorded but not billable.
with usage as (
    select
        account_id,
        usage_date,
        event_type,
        cast(quantity as bigint) as quantity
    from {{ ref('fct_usage_daily') }}
),
accounts as (
    select
        account_id,
        coalesce(parent_account_id, account_id) as customer_id,
        is_internal
    from {{ ref('dim_accounts') }}
),
account_days as (
    select distinct account_id, usage_date from usage
),
status_on_day as (
    select
        d.account_id,
        d.usage_date,
        max(case v.status
                when 'active'   then 3
                when 'past_due' then 3
                when 'trialing' then 2
                when 'canceled' then 1
                else 0 end) as status_rank
    from account_days d
    left join {{ ref('stg_subscriptions') }} s on s.account_id = d.account_id
    left join {{ ref('stg_subscription_versions') }} v
      on v.subscription_id = s.subscription_id
     and v.valid_from <= d.usage_date
     and (v.valid_to is null or d.usage_date < v.valid_to)
    group by 1, 2
)
select
    u.account_id || '|' || cast(u.usage_date as varchar) || '|' || u.event_type as usage_day_id,
    u.account_id,
    a.customer_id,
    u.usage_date,
    u.event_type,
    u.quantity,
    case coalesce(sd.status_rank, 0)
        when 3 then 'paying'
        when 2 then 'trialing'
        when 1 then 'canceled'
        else 'no_subscription'
    end as subscription_status_on_date,
    u.event_type = 'api_call' and coalesce(sd.status_rank, 0) = 3 as is_billable,
    case when u.event_type = 'api_call' and coalesce(sd.status_rank, 0) = 3 then u.quantity else 0 end as billable_quantity
from usage u
join accounts a on a.account_id = u.account_id
left join status_on_day sd on sd.account_id = u.account_id and sd.usage_date = u.usage_date
where not a.is_internal
