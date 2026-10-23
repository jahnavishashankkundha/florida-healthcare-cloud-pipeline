-- Step 1: Setup Session & Warehouse
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
USE WAREHOUSE COMPUTE_WH;

CREATE DATABASE IF NOT EXISTS florida_healthcare;
USE DATABASE florida_healthcare;
USE SCHEMA PUBLIC;

-- Step 2: Create Raw Landing Table
CREATE OR REPLACE TABLE florida_hospitals_clean (
    facility_id VARCHAR,
    facility_name VARCHAR,
    address VARCHAR,
    city VARCHAR,
    state VARCHAR,
    zip_code VARCHAR,
    county VARCHAR,
    telephone_number VARCHAR,
    hospital_type VARCHAR,
    hospital_ownership VARCHAR,
    emergency_services VARCHAR,
    birthing_friendly VARCHAR,
    overall_rating VARCHAR,
    overall_rating_footnote VARCHAR,
    mort_group_measure_count VARCHAR,
    count_facility_mort_measures VARCHAR,
    count_mort_measures_better VARCHAR,
    count_mort_measures_no_different VARCHAR,
    count_mort_measures_worse VARCHAR,
    mort_group_footnote VARCHAR,
    safety_group_measure_count VARCHAR,
    count_facility_safety_measures VARCHAR,
    count_safety_measures_better VARCHAR,
    count_safety_measures_no_different VARCHAR,
    count_safety_measures_worse VARCHAR,
    safety_group_footnote VARCHAR,
    readm_group_measure_count VARCHAR,
    count_facility_readm_measures VARCHAR,
    count_readm_measures_better VARCHAR,
    count_readm_measures_no_different VARCHAR,
    count_readm_measures_worse VARCHAR,
    readm_group_footnote VARCHAR,
    pt_exp_group_measure_count VARCHAR,
    count_facility_pt_exp_measures VARCHAR,
    pt_exp_group_footnote VARCHAR,
    te_group_measure_count VARCHAR,
    count_facility_te_measures VARCHAR,
    te_group_footnote VARCHAR
);

-- Step 3: Copy Data from S3 Stage
COPY INTO florida_hospitals_clean
FROM 's3://florida-data-2026-kjs/Florida_health.csv'
CREDENTIALS = (
    AWS_KEY_ID = '<YOUR_AWS_ACCESS_KEY_ID>'
    AWS_SECRET_KEY = '<YOUR_AWS_SECRET_ACCESS_KEY>'
)
FILE_FORMAT = (
    TYPE = 'CSV'
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
)
FORCE = TRUE;
