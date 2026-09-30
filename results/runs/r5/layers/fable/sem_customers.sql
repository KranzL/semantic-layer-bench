{{ config(materialized='table', schema='semantic') }}

-- One row per customer (logo): a real account that has no parent account.
-- Child accounts roll up to their parent and do not get their own row.
select
    p.account_id as customer_id,
    p.account_name as customer_name,
    p.created_date,
    p.country,
    p.region,
    p.segment,
    count(c.account_id) as billing_account_count,
    count(c.account_id) > 1 as has_child_accounts
from {{ ref('sem_accounts') }} p
join {{ ref('sem_accounts') }} c on c.customer_id = p.account_id
where not p.is_child_account
group by all
