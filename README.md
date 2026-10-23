Markdown
# Florida Healthcare Cloud Data Pipeline (AWS S3 → Snowflake ELT)

An end-to-end cloud data engineering pipeline that ingests, cleans, models, and analyzes public healthcare facility data from **AWS S3** into **Snowflake** using an **ELT (Extract, Load, Transform)** architecture.

---

## 🏗️ Data Architecture

                                +---------------------------------------------------+
                                |                SNOWFLAKE DWH                      |
+-------------------+               |                                                   |
|   AWS S3 Bucket   |               |  +---------------------+   +-------------------+  |   +---------------------+
| florida-data-2026 |  COPY INTO    |  |  Bronze (Raw) Layer |   | Gold (Dim) Layer  |  |   | Analytical Queries  |
|      -kjs         |  ===========> |  | florida_hospitals_  | =>|   dim_florida_    |  | =>|     & Dashboards    |
| Florida_health.csv|  (IAM Auth)   |  |        clean        |   |     hospitals     |  |   |   (Business Layer)  |
+-------------------+               |  +---------------------+   +-------------------+  |   +---------------------+
+---------------------------------------------------+


---

## 💻 Tech Stack

| Component | Tool / Technology |
| :--- | :--- |
| **Cloud Storage** | AWS S3 |
| **Access & Security** | AWS IAM (Access Keys & Permissions) |
| **Data Warehouse** | Snowflake (`COMPUTE_WH`) |
| **Data Ingestion** | Snowflake Staging & `COPY INTO` |
| **Transformation Layer** | SQL (Schema Mapping, `TRY_CAST`, Business Logic) |
| **Data Modeling** | Dimensional Modeling (Bronze → Gold Architecture) |

---

## 📊 Business Problem & Deliverable

* **Problem Statement:** Public hospital quality and ratings data are distributed as unstructured/semi-structured flat files (38 broad columns, mixed string/numeric fields, missing ratings recorded as `'Not Available'`).
* **Solution:** Standardized raw CSV ingestion from cloud storage into an enterprise data warehouse, handling schema mismatches, typing null values, and building an aggregated dimensional data model (`dim_florida_hospitals`) focused on 221 Florida healthcare facilities.

---

## 🚀 Step-by-Step Implementation

### Step 1: External Stage & Raw Ingestion Layer (Bronze)

```sql
-- 1. Setup Session Context
CREATE WAREHOUSE IF NOT EXISTS COMPUTE_WH WITH WAREHOUSE_SIZE = 'XSMALL' AUTO_SUSPEND = 60 AUTO_RESUME = TRUE;
USE WAREHOUSE COMPUTE_WH;

CREATE DATABASE IF NOT EXISTS florida_healthcare;
USE DATABASE florida_healthcare;
USE SCHEMA PUBLIC;

-- 2. Create Raw Landing Table (38 Mapped Columns)
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

-- 3. Ingest Data from AWS S3
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

```
### Step 2: Data Transformation & Analytics Model (Gold)
```SQL
-- Create Cleaned & Typed Dimensional Analytics Table
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
    
    -- Safe numeric conversion ('Not Available' -> NULL)
    TRY_CAST(overall_rating AS INT) AS overall_rating,
    TRY_CAST(mort_group_measure_count AS INT) AS mort_measure_count,
    TRY_CAST(safety_group_measure_count AS INT) AS safety_measure_count,
    TRY_CAST(readm_group_measure_count AS INT) AS readm_measure_count,
    
    -- Business Logic: Categorical Tiering
    CASE 
        WHEN TRY_CAST(overall_rating AS INT) >= 4 THEN 'High Rating (4-5★)'
        WHEN TRY_CAST(overall_rating AS INT) = 3 THEN 'Average Rating (3★)'
        WHEN TRY_CAST(overall_rating AS INT) <= 2 THEN 'Low Rating (1-2★)'
        ELSE 'Unrated / Not Reported'
    END AS rating_tier

FROM florida_hospitals_clean
WHERE state = 'FL';
```
**### Step 3: Analytical SQL Queries**
```SQL
-- Query 1: Hospital Quality Ratings & Emergency Services by Ownership Type
SELECT 
    hospital_ownership,
    COUNT(*) AS total_hospitals,
    ROUND(AVG(overall_rating), 2) AS avg_hospital_rating,
    COUNT(CASE WHEN emergency_services = 'Yes' THEN 1 END) AS emergency_service_count
FROM dim_florida_hospitals
GROUP BY hospital_ownership
ORDER BY total_hospitals DESC;

-- Query 2: Top Rated Florida Counties (Min. 3 Facilities)
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
