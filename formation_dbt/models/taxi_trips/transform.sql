{{ config(
    materialized='external',
    location='output/trips_2024_transformed.parquet', 
    format='parquet'
) }}


WITH source_data AS (
    SELECT * EXCLUDE (VendorID, RatecodeID)
    FROM {{ source('tlc_texi_trps', 'row_yellow_tripdata') }}
),

filtered_data AS (
    SELECT * 
    FROM source_data
    WHERE passenger_count > 0
      AND trip_distance > 0
      AND total_amount > 0
      AND tpep_pickup_datetime < tpep_dropoff_datetime
      AND store_and_fwd_flag = 'N'
      AND tip_amount >= 0
      AND payment_type IN (1, 2)
),

transformed_data AS (
    SELECT 
        tpep_pickup_datetime,
        tpep_dropoff_datetime,
        DATE_DIFF('minute', tpep_pickup_datetime, tpep_dropoff_datetime) AS trip_duration_minutes,
        trip_distance,
        CAST(passenger_count AS BIGINT) AS passenger_count,
        CASE 
            WHEN payment_type = 1 THEN 'Credit card'
            WHEN payment_type = 2 THEN 'Cash'
        END AS payment_method,
        store_and_fwd_flag,
        PULocationID,
        DOLocationID,
        fare_amount,
        total_amount,
        tip_amount,
        tolls_amount,
        improvement_surcharge,
        congestion_surcharge,
        extra,
        mta_tax,
        Airport_fee
    FROM filtered_data
), 

final_data AS (
    SELECT *, 
        CAST(tpep_pickup_datetime AS DATE) AS pickup_date, 
        CAST(tpep_dropoff_datetime AS DATE) AS dropoff_date
    FROM transformed_data
    WHERE pickup_date >= '2024-01-01' AND pickup_date < '2025-01-01'
      AND dropoff_date >= '2024-01-01' AND dropoff_date < '2025-01-01'
)

SELECT * EXCLUDE(pickup_date, dropoff_date)
FROM final_data
WHERE trip_duration_minutes > 0