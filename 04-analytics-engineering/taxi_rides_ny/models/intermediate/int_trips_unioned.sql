{{
    config(
        materialized='view'
    )
}}

with yellow_data as (
    select 
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
        cast(null as integer) as trip_type,
        cast(null as numeric) as ehail_fee
    from {{ ref('stg_yellow_tripdata') }}
),

green_data as (
    select 
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
    from {{ ref('stg_green_tripdata') }}
),

trips_unioned as (
    select * from yellow_data
    union all
    select * from green_data
)

select * from trips_unioned
