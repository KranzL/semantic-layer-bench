{{ config(materialized='table', schema='semantic') }}

-- One row per invoice of a real account (internal and soft-deleted accounts
-- removed). All invoice statuses are kept; is_billed marks the finalized
-- invoices (open, paid, uncollectible) that count as billings. Amounts are
-- converted to USD at the FX rate of the invoice issue date.
select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    a.customer_id,
    i.subscription_id,
    v.plan_id,
    i.invoice_type,
    i.status as invoice_status,
    i.status in ('open', 'paid', 'uncollectible') as is_billed,
    i.issued_date,
    i.due_at as due_date,
    i.period_start,
    i.period_end,
    i.currency,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as net_amount_usd,
    i.subtotal_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as subtotal_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as discount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_usd
from {{ ref('fct_invoices') }} i
join {{ ref('sem_accounts') }} a on a.account_id = i.account_id
left join {{ ref('stg_subscription_versions') }} v
    on v.subscription_id = i.subscription_id
    and v.valid_from <= i.period_start
    and (v.valid_to is null or i.period_start < v.valid_to)
