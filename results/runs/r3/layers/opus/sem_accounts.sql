-- One row per external (non-internal) billing account, including soft-deleted accounts so
-- their history is preserved. customer_id rolls child accounts up to their parent (the logo).
select
    a.account_id,
    coalesce(a.parent_account_id, a.account_id) as customer_id,
    a.account_name,
    a.country,
    a.region,
    a.segment,
    a.billing_currency,
    a.created_date,
    a.is_deleted,
    a.parent_account_id is not null as is_child_account
from {{ ref('dim_accounts') }} a
where not a.is_internal
