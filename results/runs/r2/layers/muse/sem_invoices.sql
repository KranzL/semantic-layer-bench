select
    i.invoice_id as row_key,
    i.issued_date,
    i.period_start,
    i.period_end,
    i.invoice_id,
    i.invoice_number,
    i.invoice_type,
    i.status as invoice_status,
    i.currency,
    i.account_id,
    a.account_name,
    a.segment,
    a.region,
    a.country,
    a.billing_currency,
    a.parent_account_id,
    (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit as net_usd,
    i.tax_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as tax_usd,
    i.total_minor / power(10, i.minor_unit_exponent) * i.usd_per_unit as total_usd,
    case
        when i.status not in ('draft', 'void')
        then (i.subtotal_minor - i.discount_minor) / power(10, i.minor_unit_exponent) * i.usd_per_unit
        else 0
    end as billed_usd
from {{ ref('fct_invoices') }} i
join {{ ref('dim_accounts') }} a on a.account_id = i.account_id
where not a.is_internal and not a.is_deleted
