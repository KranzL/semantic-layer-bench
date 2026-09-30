{{ config(materialized='table', schema='semantic') }}

-- One row per account. A "customer" (logo) is the ultimate parent account:
-- subsidiaries (parent_account_id set) roll up to their parent. The hierarchy is one level deep.
-- is_reportable = false for internal/test accounts and soft-deleted accounts; every fact helper
-- model in this folder drops non-reportable accounts.
select
    a.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    a.account_name,
    a.created_date,
    a.country,
    a.region,
    a.segment,
    a.billing_currency,
    a.is_internal,
    a.is_deleted,
    a.parent_account_id is not null as is_subsidiary,
    not a.is_internal and not a.is_deleted as is_reportable
from {{ ref('dim_accounts') }} a
