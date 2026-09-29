{{ config(materialized='table', schema='semantic') }}

-- One row per customer (logo). A customer is a top-level billing account:
-- an account with no parent_account_id. Child accounts bill separately but
-- roll up to their parent here so customer counts are not inflated.
-- Internal accounts are kept in this dimension (flagged) but every fact helper
-- in models/semantic excludes them.
with accounts as (
    select * from {{ ref('dim_accounts') }}
),
top_level as (
    select * from accounts where parent_account_id is null
),
children as (
    select parent_account_id, count(*) as child_account_count
    from accounts
    where parent_account_id is not null
    group by 1
)
select
    t.account_id                               as customer_id,
    t.account_name                             as customer_name,
    t.segment,
    t.region,
    t.country,
    t.billing_currency,
    t.created_date,
    t.is_internal,
    t.is_deleted,
    coalesce(c.child_account_count, 0)         as child_account_count,
    coalesce(c.child_account_count, 0) > 0     as has_child_accounts
from top_level t
left join children c on c.parent_account_id = t.account_id
