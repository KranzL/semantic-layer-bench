{{ config(materialized='table', schema='semantic') }}

-- Reportable billing accounts: excludes Relay's own internal accounts (QA, demo, sandbox) and
-- soft-deleted accounts. Each account is mapped to its customer (logo): the parent account
-- when one exists, otherwise the account itself.
select
    a.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    a.account_name,
    a.created_date,
    a.country,
    a.region,
    a.segment,
    a.billing_currency,
    a.parent_account_id is not null as is_child_account
from {{ ref('dim_accounts') }} a
left join {{ ref('dim_accounts') }} p on p.account_id = a.parent_account_id
where not a.is_internal
  and not a.is_deleted
  and not coalesce(p.is_internal, false)
  and not coalesce(p.is_deleted, false)
