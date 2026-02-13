{{
    config(
        materialized='view'
    )
}}

with fhv_data as (
    select 
        -- identifiers
        {{ dbt_utils.generate_surrogate_key(['dispatching_base_num', 'pickup_datetime']) }} as tripid,
        dispatching_base_num,
        affiliated_base_number,
        
        -- timestamps
        cast(pickup_datetime as timestamp) as pickup_datetime,
        cast(dropOff_datetime as timestamp) as dropoff_datetime,
        
        -- trip info
        cast(PUlocationID as integer) as pickup_locationid,
        cast(DOlocationID as integer) as dropoff_locationid,
        cast(SR_Flag as integer) as sr_flag
        
    from {{ source('nytaxi', 'fhv_tripdata') }}
    
    -- Filter out records where dispatching_base_num is NULL
    where dispatching_base_num is not null
)

select * from fhv_data

-- dbt build --select <model_name> --vars '{"is_test_run": false}'
{% if var('is_test_run', default=true) %}

  limit 100

{% endif %}
