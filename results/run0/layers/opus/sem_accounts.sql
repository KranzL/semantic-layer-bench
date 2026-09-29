-- One row per external (non-internal) billing account, with the customer (top-level parent account) it rolls up to.
select
    a.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    a.parent_account_id is not null as is_subsidiary,
    a.account_name,
    a.created_date,
    a.country,
    a.region,
    a.segment,
    a.billing_currency,
    a.is_deleted
from {{ ref('dim_accounts') }} a
where not a.is_internal
