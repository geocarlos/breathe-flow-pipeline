-- Simple staging model for raw OpenAQ data
with raw as (
  select *
  from {{ source('openaq','raw') }}
)

select
  * except (id),
  cast(null as string) as ingestion_id -- placeholder
from raw
