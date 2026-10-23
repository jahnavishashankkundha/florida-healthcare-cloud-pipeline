USE DATABASE florida_healthcare;
USE SCHEMA PUBLIC;

-- Query 1: Hospital Ratings by Ownership Type
SELECT 
    hospital_ownership,
    COUNT(*) AS total_hospitals,
    ROUND(AVG(overall_rating), 2) AS avg_hospital_rating,
    COUNT(CASE WHEN emergency_services = 'Yes' THEN 1 END) AS emergency_service_count
FROM dim_florida_hospitals
GROUP BY hospital_ownership
ORDER BY total_hospitals DESC;

-- Query 2: Top Florida Counties by Healthcare Quality
SELECT 
    county,
    COUNT(*) AS total_hospitals,
    ROUND(AVG(overall_rating), 2) AS avg_county_rating,
    COUNT(CASE WHEN rating_tier = 'High Rating (4-5★)' THEN 1 END) AS high_rated_hospitals
FROM dim_florida_hospitals
WHERE county IS NOT NULL
GROUP BY county
HAVING COUNT(*) >= 3
ORDER BY avg_county_rating DESC;
