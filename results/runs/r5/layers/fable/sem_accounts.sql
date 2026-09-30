{{ config(materialized='table', schema='semantic') }}

-- One row per real billing account. Internal (Relay test/demo/sandbox) and
-- soft-deleted accounts are removed. Each account is mapped to its customer
-- (logo): the parent account when one exists, otherwise the account itself.
select
    a.account_id,
    a.account_name,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    a.parent_account_id is not null as is_child_account,
    a.created_date,
    a.country,
    a.region,
    a.segment,
    a.billing_currency
from {{ ref('dim_accounts') }} a
where not a.is_internal
  and not a.is_deleted
