with ranked as (
    select
        s.subscription_id,
        s.account_id,
        s.currency,
        v.plan_id,
        v.status,
        v.valid_from,
        row_number() over (partition by s.subscription_id order by v.valid_from desc) as rn
    from {{ ref('stg_subscriptions') }} s
    join {{ ref('stg_subscription_versions') }} v on v.subscription_id = s.subscription_id
)
select subscription_id, account_id, currency, plan_id, status as current_status
from ranked
where rn = 1
