{{ config(materialized='table', schema='marts') }}

/*
    Daily usage per account and event type (same grain as fct_usage_daily), enriched with the
    subscription status that was in force for the account on the usage date and a billable flag.

    Billable usage = api_call events on a day when the account had an active or past_due
    subscription. health_check events are a fixed platform heartbeat (288 per day) and are never
    billable. Usage during a trial, after cancellation, or before any subscription exists is not
    billable. Internal accounts are kept in this table and excluded at the metric level.

    When an account has more than one subscription version in force on a date (possible when an
    old canceled subscription's final version is open-ended and a new subscription has started),
    the status is chosen in the order active > past_due > trialing > canceled.
*/

with usage as (
    select
        account_id,
        usage_date,
        event_type,
        cast(quantity as bigint) as quantity
    from {{ ref('fct_usage_daily') }}
),

versions as (
    select
        s.account_id,
        v.subscription_id,
        v.valid_from,
        v.valid_to,
        v.status,
        v.plan_id
    from {{ ref('stg_subscription_versions') }} v
    join {{ ref('stg_subscriptions') }} s on s.subscription_id = v.subscription_id
),

account_days as (
    select distinct account_id, usage_date from usage
),

status_on_date as (
    select
        d.account_id,
        d.usage_date,
        v.subscription_id,
        v.status,
        v.plan_id,
        row_number() over (
            partition by d.account_id, d.usage_date
            order by
                case v.status
                    when 'active' then 1
                    when 'past_due' then 2
                    when 'trialing' then 3
                    when 'canceled' then 4
                    else 5
                end,
                v.valid_from desc
        ) as rn
    from account_days d
    join versions v
        on v.account_id = d.account_id
        and v.valid_from <= d.usage_date
        and (v.valid_to is null or d.usage_date < v.valid_to)
)

select
    u.account_id || '|' || cast(u.usage_date as varchar) || '|' || u.event_type as usage_day_id,
    u.account_id,
    u.usage_date,
    u.event_type,
    u.quantity,
    coalesce(s.status, 'none') as subscription_status_on_date,
    s.subscription_id,
    s.plan_id,
    u.event_type = 'api_call' as is_metered_event,
    u.event_type = 'api_call' and coalesce(s.status, 'none') in ('active', 'past_due') as is_billable
from usage u
left join status_on_date s
    on s.account_id = u.account_id
    and s.usage_date = u.usage_date
    and s.rn = 1
