select
    account_id,
    account_name,
    cast(created_at as date) as created_date,
    country,
    region,
    segment,
    billing_currency,
    is_internal,
    parent_account_id,
    deleted_at,
    deleted_at is not null as is_deleted
from {{ ref('stg_accounts') }}
