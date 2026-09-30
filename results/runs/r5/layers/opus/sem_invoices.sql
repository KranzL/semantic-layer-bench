{{ config(materialized='table', schema='semantic') }}

-- One row per invoice on a reportable account (all statuses kept; measures filter status).
-- Amounts converted from minor units with the currency exponent and to USD at the issue-date rate.
-- plan_id = plan of the subscription version in effect at the start of the billed period
-- (null for services invoices).
select
    i.invoice_id,
    i.account_id,
    a.customer_id,
    i.subscription_id,
    v.plan_id,
    i.invoice_type,
    i.status as invoice_status,
    i.status in ('open', 'paid', 'uncollectible') as is_billed,
    i.issued_date,
    i.currency,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) as net_amount_local,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as net_amount_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as discount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_usd
from {{ ref('fct_invoices') }} i
join {{ ref('sem_accounts') }} a on a.account_id = i.account_id
left join {{ ref('stg_subscription_versions') }} v
    on v.subscription_id = i.subscription_id
    and v.valid_from <= i.period_start
    and (v.valid_to is null or i.period_start < v.valid_to)
where a.is_reportable
