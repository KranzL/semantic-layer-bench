{{ config(materialized='table', schema='semantic') }}

-- One row per billing account (every row in dim_accounts, nothing filtered out).
-- Adds the reporting flags the semantic layer relies on:
--   customer_id   : the top-level ("logo") account, i.e. the parent account when the
--                   account is a child, otherwise the account itself.
--   is_reportable : true for accounts that count as real customers. Internal accounts
--                   (Relay QA / Demo / Sandbox, is_internal = true) and soft-deleted
--                   accounts (deleted_at is set; they never had an invoice or usage) are
--                   excluded from every fact model in the semantic layer.
with accounts as (
    select * from {{ ref('dim_accounts') }}
)
select
    a.account_id,
    a.account_name,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    a.parent_account_id,
    case
        when a.parent_account_id is not null then 'child'
        when exists (select 1 from accounts c where c.parent_account_id = a.account_id) then 'parent'
        else 'standalone'
    end as account_hierarchy_role,
    a.created_date,
    a.country,
    a.region,
    a.segment,
    a.billing_currency,
    a.is_internal,
    a.is_deleted,
    a.deleted_at,
    (not a.is_internal and not a.is_deleted) as is_reportable
from accounts a
