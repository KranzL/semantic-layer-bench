-- Issued invoices for external accounts: status open, paid or uncollectible.
-- Excludes void invoices (cancelled / reissued duplicates), draft invoices (not yet issued)
-- and internal accounts. Amounts are converted from minor units to USD at the issue-date FX rate.
select
    i.invoice_id,
    i.invoice_number,
    i.account_id,
    a.customer_id,
    i.subscription_id,
    v.plan_id,
    i.invoice_type,
    i.status,
    i.currency,
    i.issued_date,
    d.fiscal_year,
    'FY' || d.fiscal_year || ' Q' || d.fiscal_quarter as fiscal_quarter,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as billings_usd,
    i.discount_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as discount_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_usd
from {{ ref('fct_invoices') }} i
join {{ ref('sem_accounts') }} a on a.account_id = i.account_id
join {{ ref('dim_date') }} d on d.date_day = i.issued_date
left join {{ ref('stg_subscription_versions') }} v
    on v.subscription_id = i.subscription_id
   and i.period_start >= v.valid_from
   and (v.valid_to is null or i.period_start < v.valid_to)
where i.status in ('open', 'paid', 'uncollectible')
