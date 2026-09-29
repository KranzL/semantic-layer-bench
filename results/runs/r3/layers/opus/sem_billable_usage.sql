-- Billable usage: daily api_call quantity per external account, only on days the account had
-- a paying (active or past_due) subscription version. Excludes health_check events (automated
-- system pings), usage during trials or after cancellation, and internal accounts.
select
    u.account_id || '-' || strftime(u.usage_date, '%Y%m%d') as account_usage_day_id,
    u.account_id,
    a.customer_id,
    u.usage_date,
    d.fiscal_year,
    'FY' || d.fiscal_year || ' Q' || d.fiscal_quarter as fiscal_quarter,
    u.quantity as api_calls
from {{ ref('fct_usage_daily') }} u
join {{ ref('sem_accounts') }} a on a.account_id = u.account_id
join {{ ref('dim_date') }} d on d.date_day = u.usage_date
where u.event_type = 'api_call'
  and exists (
      select 1
      from {{ ref('stg_subscriptions') }} s
      join {{ ref('stg_subscription_versions') }} v on v.subscription_id = s.subscription_id
      where s.account_id = u.account_id
        and v.status in ('active', 'past_due')
        and v.valid_from <= u.usage_date
        and (v.valid_to is null or u.usage_date < v.valid_to)
  )
