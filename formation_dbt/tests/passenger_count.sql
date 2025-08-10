SELECT *
FROM {{ref('transform')}}
WHERE 
    passenger_count <= 0
    AND passenger_count != CAST(passenger_count AS BIGINT)