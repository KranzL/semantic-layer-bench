select
    p.payment_id as row_key,
    p.received_date,
    p.payment_id,
    p.invoice_id,
    p.status as payment_status,
    p.method as payment_method,
    p.currency,
    p.account_id,
    a.account_name,
    a.segment,
    a.region,
    a.country,
    a.billing_currency,
    a.parent_account_id,
    case
        when p.status = 'succeeded'
        then p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit
        else 0
    end as collected_usd,
    case
        when p.status = 'failed'
        then p.amount_minor / power(10, p.minor_unit_exponent) * p.usd_per_unit
        else 0
    end as failed_usd,
    case when p.status = 'failed' then p.payment_id end as failed_payment_id
from {{ ref('fct_payments') }} p
join {{ ref('dim_accounts') }} a on a.account_id = p.account_id
where not a.is_internal and not a.is_deleted
