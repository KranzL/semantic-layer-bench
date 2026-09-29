select * from {{ source('raw', 'invoices') }}
