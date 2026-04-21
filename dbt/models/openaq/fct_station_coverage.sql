{{
  config(
    materialized='incremental',
    unique_key='coverage_id',
    incremental_strategy='merge',
    partition_by={
      "field": "snapshot_date",
      "data_type": "date",
      "granularity": "day"
    },
    cluster_by=['country_code']
  )
}}

with snapshots as (
    select *
    from {{ ref('stg_openaq_raw') }}
    {% if is_incremental() %}
    -- only aggregate dates we haven't processed yet
    where ingested_date > (select max(snapshot_date) from {{ this }})
    {% endif %}
),

coverage as (
    select
        TO_HEX(MD5(CONCAT(
            country_code, '|', CAST(ingested_date AS STRING)
        )))                                     as coverage_id,

        country_code,
        country_name,
        ingested_date                           as snapshot_date,

        COUNT(DISTINCT station_id)              as active_stations,
        ROUND(AVG(sensor_count), 1)             as avg_sensors_per_station,
        COUNTIF(is_monitor = true)              as monitor_stations,
        COUNTIF(is_mobile = true)               as mobile_stations,

        MIN(last_measured_at)                   as oldest_last_measurement,
        MAX(last_measured_at)                   as newest_last_measurement
    from snapshots
    group by 1, 2, 3, 4
)

select * from coverage
