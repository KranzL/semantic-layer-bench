-- One row per external (non-internal) account, with the customer it rolls up to.
-- Child accounts roll up to their parent account; segment/region/country are taken from that customer (parent).
select
    a.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    r.account_name as customer_name,
    r.segment as customer_segment,
    r.region as customer_region,
    r.country as customer_country,
    r.billing_currency as customer_billing_currency,
    a.parent_account_id is not null as is_child_account,
    cast(a.created_date as date) as created_date,
    a.is_deleted
from {{ ref('dim_accounts') }} a
join {{ ref('dim_accounts') }} r on r.account_id = coalesce(a.parent_account_id, a.account_id)
where not a.is_internal
