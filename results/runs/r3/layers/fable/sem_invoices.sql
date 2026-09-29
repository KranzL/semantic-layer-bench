{{ config(materialized='table', schema='semantic') }}

-- One row per invoice issued to a non-internal account, with amounts converted
-- to major currency units and to USD at the FX rate on the issue date.
-- All statuses are kept (draft, open, paid, uncollectible, void) so that
-- measures can apply the right status rule explicitly.
with invoices as (
    select * from {{ ref('fct_invoices') }}
),
accounts as (
    select account_id, is_internal from {{ ref('dim_accounts') }}
)
select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    i.subscription_id,
    i.invoice_type,
    i.status as invoice_status,
    i.issued_date,
    i.due_at as due_date,
    i.period_start,
    i.period_end,
    i.currency,
    i.minor_unit_exponent,
    i.usd_per_unit,
    -- finalized = issued to the customer and not reversed (excludes draft and void)
    i.status not in ('draft', 'void') as is_finalized,
    i.status = 'paid' as is_paid,
    i.status = 'open' as is_open,
    i.status = 'uncollectible' as is_uncollectible,
    i.subtotal_minor / power(10, i.minor_unit_exponent) as subtotal_local,
    i.discount_minor / power(10, i.minor_unit_exponent) as discount_local,
    i.tax_minor / power(10, i.minor_unit_exponent) as tax_local,
    i.total_minor / power(10, i.minor_unit_exponent) as total_local,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) as net_local,
    i.subtotal_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as subtotal_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as discount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_usd,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as net_usd
from invoices i
join accounts a on a.account_id = i.account_id
where not a.is_internal
