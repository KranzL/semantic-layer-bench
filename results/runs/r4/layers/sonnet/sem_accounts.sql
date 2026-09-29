{{ config(materialized='table') }}
-- One row per external (non-internal) account. Segment, region, country and billing currency are taken
-- from the account's root customer (the parent account for child accounts, otherwise the account itself).
select
    a.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    r.segment,
    r.region,
    r.country,
    r.billing_currency,
    a.is_deleted
from {{ ref('dim_accounts') }} a
join {{ ref('dim_accounts') }} r on r.account_id = coalesce(a.parent_account_id, a.account_id)
where not a.is_internal
