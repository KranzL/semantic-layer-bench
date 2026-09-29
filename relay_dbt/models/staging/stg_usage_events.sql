select * from {{ source('raw', 'usage_events') }}
