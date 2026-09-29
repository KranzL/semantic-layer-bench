{{ config(materialized='table', schema='semantic') }}

-- One row per customer ("logo"): the top-level account. Child accounts
-- (parent_account_id set) are rolled up into their parent and do not appear here.
-- Attributes (segment, region, country, billing currency) are those of the top-level account.
with accounts as (
    select * from {{ ref('sl_accounts') }}
)
select
    p.account_id as customer_id,
    p.account_name as customer_name,
    p.created_date as customer_created_date,
    p.country,
    p.region,
    p.segment,
    p.billing_currency,
    p.is_internal,
    p.is_deleted,
    p.is_reportable,
    (select count(*) from accounts c where c.parent_account_id = p.account_id) as child_account_count,
    (select count(*) from accounts c where c.parent_account_id = p.account_id) > 0 as has_child_accounts
from accounts p
where p.parent_account_id is null
