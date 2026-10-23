USE DATABASE florida_healthcare;
USE SCHEMA PUBLIC;

-- Build Cleaned & Typed Dimensional Table
CREATE OR REPLACE TABLE dim_florida_hospitals AS
SELECT 
    facility_id,
    facility_name,
    address,
    city,
    county,
    zip_code,
    telephone_number,
    hospital_type,
    hospital_ownership,
    emergency_services,
    birthing_friendly,
    
    -- Numeric conversion handling string nulls ('Not Available' -> NULL)
    TRY_CAST(overall_rating AS INT) AS overall_rating,
    TRY_CAST(mort_group_measure_count AS INT) AS mort_measure_count,
    TRY_CAST(safety_group_measure_count AS INT) AS safety_measure_count,
    TRY_CAST(readm_group_measure_count AS INT) AS readm_measure_count,
    
    -- Rating Tiers
    CASE 
        WHEN TRY_CAST(overall_rating AS INT) >= 4 THEN 'High Rating (4-5★)'
        WHEN TRY_CAST(overall_rating AS INT) = 3 THEN 'Average Rating (3★)'
        WHEN TRY_CAST(overall_rating AS INT) <= 2 THEN 'Low Rating (1-2★)'
        ELSE 'Unrated / Not Reported'
    END AS rating_tier

FROM florida_hospitals_clean
WHERE state = 'FL';
