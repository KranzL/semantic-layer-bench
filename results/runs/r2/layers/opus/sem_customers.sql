{{ config(materialized='table', schema='marts') }}

-- One row per customer (ultimate parent account). Attributes are taken from
-- the parent account, so a subsidiary's revenue is reported under its
-- parent's segment and region when sliced by customer attributes.
select
    a.account_id as customer_id,
    a.account_name as customer_name,
    a.country,
    a.region,
    a.segment,
    a.billing_currency,
    a.is_internal,
    a.is_deleted,
    (select count(*) from {{ ref('dim_accounts') }} c where c.parent_account_id = a.account_id) as subsidiary_count
from {{ ref('dim_accounts') }} a
where a.parent_account_id is null
