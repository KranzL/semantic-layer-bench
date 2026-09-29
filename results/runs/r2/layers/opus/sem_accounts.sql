{{ config(materialized='table', schema='marts') }}

-- One row per account (billing entity). customer_id is the ultimate parent
-- account: subsidiaries roll up to their parent, standalone accounts are their
-- own customer. Hierarchies are one level deep in the source data.
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
