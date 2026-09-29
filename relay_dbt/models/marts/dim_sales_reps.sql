select rep_id, rep_name, team, region, hired_at from {{ ref('stg_sales_reps') }}
