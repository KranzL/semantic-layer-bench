{{ config(materialized='table', schema='semantic') }}

-- One row per customer (logo): every reportable account that is either a top-level account
-- or the parent of other accounts. Attributes are those of the top-level account.
with customer_ids as (
    select distinct customer_id from {{ ref('sem_accounts') }}
),
child_counts as (
    select customer_id, count(*) as child_account_count
    from {{ ref('sem_accounts') }}
    where is_child_account
    group by 1
)
select
    c.customer_id,
    a.account_name as customer_name,
    a.created_date,
    a.country,
    a.region,
    a.segment,
    a.billing_currency,
    coalesce(cc.child_account_count, 0) > 0 as has_child_accounts
from customer_ids c
join {{ ref('dim_accounts') }} a on a.account_id = c.customer_id
left join child_counts cc on cc.customer_id = c.customer_id
