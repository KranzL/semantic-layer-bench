-- One row per external customer. A customer is a parent account, or a standalone account with no parent;
-- child accounts roll up to their parent, whose segment, region, country and billing currency apply.
select distinct
    customer_id,
    customer_name,
    customer_segment,
    customer_region,
    customer_country,
    customer_billing_currency
from {{ ref('sem_accounts') }}
