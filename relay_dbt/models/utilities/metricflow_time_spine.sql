select cast(date_day as date) as date_day from {{ ref('dim_date') }}
