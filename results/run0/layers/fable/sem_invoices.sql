{{ config(materialized='table', schema='semantic') }}

-- One row per invoice, excluding internal accounts, with amounts converted to
-- major currency units and to USD at the FX rate on the issue date.
-- Billing status flags:
--   is_billable   status is open, paid or uncollectible: the invoice was really
--                 issued to the customer. Draft and void invoices are not billings.
-- net_amount = subtotal - discount, before tax. Sales tax is a pass-through
-- liability and is kept separate from billings and revenue.
-- plan_id / billing_interval come from the subscription version in force at
-- period_start (null for services invoices, which have no subscription).
with invoices as (
    select * from {{ ref('fct_invoices') }}
),
accounts as (
    select
        account_id,
        coalesce(parent_account_id, account_id) as customer_id,
        is_internal
    from {{ ref('dim_accounts') }}
),
version_at_period_start as (
    select
        i.invoice_id,
        v.plan_id,
        v.seats,
        row_number() over (partition by i.invoice_id order by v.valid_from desc, v.version_id desc) as rn
    from invoices i
    join {{ ref('stg_subscription_versions') }} v
      on v.subscription_id = i.subscription_id
     and v.valid_from <= i.period_start
     and (v.valid_to is null or i.period_start < v.valid_to)
),
plans as (
    select plan_id, plan_family, billing_interval from {{ ref('dim_plans') }}
)
select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    a.customer_id,
    i.subscription_id,
    v.plan_id,
    p.plan_family,
    p.billing_interval,
    v.seats                                                   as invoiced_seats,
    i.invoice_type,
    i.status,
    i.issued_at,
    i.issued_date,
    i.due_at                                                  as due_date,
    i.period_start,
    i.period_end,
    datediff('day', i.period_start, i.period_end)             as service_period_days,
    i.currency,
    i.minor_unit_exponent,
    i.usd_per_unit,
    i.status not in ('draft', 'void')                         as is_billable,
    i.status = 'paid'                                         as is_paid,
    i.status = 'open'                                         as is_open,
    i.status = 'uncollectible'                                as is_uncollectible,
    i.status = 'void'                                         as is_void,
    i.status = 'draft'                                        as is_draft,
    i.subtotal_minor / power(10, i.minor_unit_exponent)                        as subtotal_local,
    i.discount_minor / power(10, i.minor_unit_exponent)                        as discount_local,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent)   as net_amount_local,
    i.tax_minor / power(10, i.minor_unit_exponent)                             as tax_local,
    i.total_minor / power(10, i.minor_unit_exponent)                           as total_local,
    i.subtotal_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit                       as subtotal_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit                       as discount_usd,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit  as net_amount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit                            as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit                          as total_usd
from invoices i
join accounts a on a.account_id = i.account_id
left join version_at_period_start v on v.invoice_id = i.invoice_id and v.rn = 1
left join plans p on p.plan_id = v.plan_id
where not a.is_internal
