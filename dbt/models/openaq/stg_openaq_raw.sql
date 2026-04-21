{{
  config(
    materialized='incremental',
    unique_key='snapshot_id',
    incremental_strategy='merge',
    partition_by={
      "field": "ingested_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['country_code']
  )
}}

with source as (
    select *
    from {{ source('openaq', 'raw') }}
    {% if is_incremental() %}
    -- only process rows newer than the latest ingestion already in this table
    where TIMESTAMP(_ingested_at) > (select max(ingested_at) from {{ this }})
    {% endif %}
),

staged as (
    select
        -- Unique identifier: hash of station id + ingestion timestamp
        TO_HEX(MD5(CONCAT(
            CAST(id AS STRING), '|', CAST(_ingested_at AS STRING)
        )))                                     as snapshot_id,

        -- Station identifiers
        CAST(id AS INT64)                       as station_id,
        name                                    as station_name,
        locality,
        timezone,

        -- Location
        _country_code                           as country_code,
        country.name                            as country_name,
        coordinates.latitude                    as latitude,
        coordinates.longitude                   as longitude,

        -- Measurement timing
        TIMESTAMP(datetimeLast.utc)             as last_measured_at,
        TIMESTAMP(datetimeFirst.utc)            as first_measured_at,

        -- Sensor metadata
        ARRAY_LENGTH(sensors)                   as sensor_count,

        -- Station type flags
        isMobile                                as is_mobile,
        isMonitor                               as is_monitor,

        -- Ingestion metadata
        TIMESTAMP(_ingested_at)                 as ingested_at,
        DATE(TIMESTAMP(_ingested_at))           as ingested_date
    from source
)

select * from staged
