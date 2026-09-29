-- One row per customer (logo): a top-level external account plus any child accounts.
-- Attributes come from the top-level (parent) account.
select
    p.account_id as customer_id,
    p.account_name as customer_name,
    p.country,
    p.region,
    p.segment,
    p.billing_currency,
    p.created_date,
    p.deleted_at is not null as is_deleted,
    (select count(*) from {{ ref('dim_accounts') }} c where c.parent_account_id = p.account_id) as child_account_count
from {{ ref('dim_accounts') }} p
where p.parent_account_id is null
  and not p.is_internal
