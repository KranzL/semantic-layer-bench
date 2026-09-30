{{ config(materialized='table', schema='semantic') }}

-- One row per customer (logo) = reportable top-level account. Attributes are the parent's own.
select
    account_id as customer_id,
    account_name as customer_name,
    created_date,
    country,
    region,
    segment,
    billing_currency
from {{ ref('sem_accounts') }}
where is_reportable and not is_subsidiary
