{{ config(materialized='table', schema='semantic') }}

-- One row per non-internal account per day per event type, with the account's
-- subscription status on that day. Usage is billable only when the event type
-- is api_call and the account had an active or past_due subscription that day.
-- health_check events are platform monitoring traffic and are never billable.
-- Usage during trials, after cancellation, or by internal accounts is kept in
-- the raw quantity but flagged not billable.
with usage as (
    select * from {{ ref('fct_usage_daily') }}
),
accounts as (
    select account_id, is_internal from {{ ref('dim_accounts') }}
),
subscriptions as (
    select subscription_id, account_id from {{ ref('stg_subscriptions') }}
),
versions as (
    select subscription_id, valid_from, valid_to, status from {{ ref('stg_subscription_versions') }}
),
account_days as (
    select distinct account_id, usage_date from usage
),
status_on_day as (
    select
        d.account_id,
        d.usage_date,
        max(
            case v.status
                when 'active' then 4
                when 'past_due' then 3
                when 'trialing' then 2
                when 'canceled' then 1
            end
        ) as status_rank
    from account_days d
    left join subscriptions s on s.account_id = d.account_id
    left join versions v
        on v.subscription_id = s.subscription_id
       and v.valid_from <= d.usage_date
       and (v.valid_to is null or v.valid_to > d.usage_date)
    group by 1, 2
),
labelled as (
    select
        u.account_id,
        u.usage_date,
        u.event_type,
        cast(u.quantity as bigint) as quantity,
        case sd.status_rank
            when 4 then 'active'
            when 3 then 'past_due'
            when 2 then 'trialing'
            when 1 then 'canceled'
            else 'no_subscription'
        end as subscription_status_on_date
    from usage u
    join accounts a on a.account_id = u.account_id
    left join status_on_day sd on sd.account_id = u.account_id and sd.usage_date = u.usage_date
    where not a.is_internal
)
select
    account_id || '|' || cast(usage_date as varchar) || '|' || event_type as usage_day_id,
    account_id,
    usage_date,
    event_type,
    subscription_status_on_date,
    quantity,
    event_type = 'api_call' and subscription_status_on_date in ('active', 'past_due') as is_billable,
    case when event_type = 'api_call' and subscription_status_on_date in ('active', 'past_due') then quantity else 0 end as billable_quantity,
    case when event_type = 'api_call' then quantity else 0 end as api_call_quantity,
    case when event_type = 'health_check' then quantity else 0 end as health_check_quantity
from labelled
