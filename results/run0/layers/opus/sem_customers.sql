-- One row per customer (logo): a top-level account (no parent) that is not internal.
-- Subsidiary accounts roll up to their parent's customer_id.
select
    a.account_id as customer_id,
    a.account_name as customer_name,
    a.created_date,
    a.country,
    a.region,
    a.segment,
    a.billing_currency,
    a.is_deleted,
    (select count(*) from {{ ref('dim_accounts') }} c where c.parent_account_id = a.account_id) as subsidiary_count
from {{ ref('dim_accounts') }} a
where not a.is_internal
  and a.parent_account_id is null
