{{
    config(
        materialized='table'
    )
}}

with trips as (
    select * from {{ ref('int_trips') }}
),

dim_zones as (
    select * from {{ ref('dim_zones') }}
)

select
    trips.trip_id,
    trips.tripid,
    trips.vendorid,
    trips.service_type,
    trips.ratecodeid,
    trips.pickup_locationid,
    pickup_zone.borough as pickup_borough,
    pickup_zone.zone as pickup_zone,
    trips.dropoff_locationid,
    dropoff_zone.borough as dropoff_borough,
    dropoff_zone.zone as dropoff_zone,
    trips.pickup_datetime,
    trips.dropoff_datetime,
    trips.store_and_fwd_flag,
    trips.passenger_count,
    trips.trip_distance,
    trips.trip_type,
    trips.fare_amount,
    trips.extra,
    trips.mta_tax,
    trips.tip_amount,
    trips.tolls_amount,
    trips.ehail_fee,
    trips.improvement_surcharge,
    trips.total_amount,
    trips.payment_type,
    trips.congestion_surcharge
from trips
left join dim_zones as pickup_zone
    on trips.pickup_locationid = pickup_zone.locationid
left join dim_zones as dropoff_zone
    on trips.dropoff_locationid = dropoff_zone.locationid
