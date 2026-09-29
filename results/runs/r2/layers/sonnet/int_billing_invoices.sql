{{ config(materialized='table', schema='marts') }}

-- fct_invoices enriched with the plan that was effective on the subscription at the
-- invoice's period_start (services invoices have no subscription_id and so get a null
-- plan), and with billed_amount_usd = (subtotal - discount) converted to USD, i.e. the
-- net amount billed before tax. Tax is excluded because it is collected on behalf of tax
-- authorities, not company revenue. Internal/test accounts are dropped here so billings
-- metrics are automatically customer-only.
select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    i.subscription_id,
    i.invoice_type,
    i.status,
    i.issued_date,
    i.period_start,
    i.period_end,
    i.currency,
    (i.subtotal_minor - i.discount_minor)
        / power(10, i.minor_unit_exponent)
        * i.usd_per_unit
        as billed_amount_usd,
    v.plan_id,
    p.plan_family,
    p.billing_interval
from {{ ref('fct_invoices') }} i
join {{ ref('dim_accounts') }} a on a.account_id = i.account_id
left join {{ ref('stg_subscription_versions') }} v
    on v.subscription_id = i.subscription_id
    and v.valid_from <= i.period_start
    and (v.valid_to is null or v.valid_to > i.period_start)
left join {{ ref('dim_plans') }} p on p.plan_id = v.plan_id
where not a.is_internal
