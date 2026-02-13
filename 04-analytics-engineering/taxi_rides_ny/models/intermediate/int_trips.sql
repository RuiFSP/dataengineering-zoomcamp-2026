{{
    config(
        materialized='view'
    )
}}

-- Deduplicate and enrich trip data from the unioned trips
-- Uses 4-column deduplication strategy: vendor_id, pickup_datetime, pickup_location_id, service_type

with unioned as (
    select * from {{ ref('int_trips_unioned') }}
),

cleaned_and_enriched as (
    select
        -- Generate unique trip identifier (surrogate key)
        {{ dbt_utils.generate_surrogate_key(['vendorid', 'pickup_datetime', 'pickup_locationid', 'service_type']) }} as trip_id,
        
        -- All original columns
        tripid,
        vendorid,
        ratecodeid,
        pickup_locationid,
        dropoff_locationid,
        pickup_datetime,
        dropoff_datetime,
        store_and_fwd_flag,
        passenger_count,
        trip_distance,
        payment_type,
        fare_amount,
        extra,
        mta_tax,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        total_amount,
        congestion_surcharge,
        service_type,
        trip_type,
        ehail_fee
    from unioned
)

select * from cleaned_and_enriched
-- Deduplication: For duplicate trips (same vendor+time+location+service), keep first by dropoff_datetime
qualify row_number() over(
    partition by vendorid, pickup_datetime, pickup_locationid, service_type
    order by dropoff_datetime
) = 1
