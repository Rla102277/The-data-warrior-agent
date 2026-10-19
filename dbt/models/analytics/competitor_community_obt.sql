{{ config(materialized='view', schema='analytics', alias='competitor_community_obt') }}

-- Community + side competitor analysis grain.
-- side: competitor_web | gbp_web | gbp_erp
-- One row per community_key + side.
-- Price: website list for *_web; SGM base / plan base for gbp_erp.

SELECT
    community_key,
    side,
    MAX(source_group) AS source_group,
    MAX(community_name) AS community_name,
    MAX(city) AS city,
    MAX(state) AS state,
    MAX(country) AS country,
    MAX(project_id) AS project_id,
    MAX(project_name) AS project_name,
    MAX(price_basis) AS price_basis,
    SUM(CASE WHEN LOWER(record_type) = 'inventory' THEN 1 ELSE 0 END) AS inventory_count,
    SUM(CASE
        WHEN LOWER(record_type) = 'inventory'
             AND LOWER(COALESCE(availability_group, '')) = 'available'
            THEN 1 ELSE 0
    END) AS available_inventory_count,
    SUM(CASE WHEN LOWER(record_type) = 'plan' THEN 1 ELSE 0 END) AS plan_count,
    AVG(CASE WHEN LOWER(record_type) = 'inventory' THEN CAST(price AS FLOAT) END) AS avg_inventory_price,
    AVG(CASE WHEN LOWER(record_type) = 'plan' THEN CAST(price AS FLOAT) END) AS avg_plan_price,
    AVG(CASE WHEN LOWER(record_type) = 'inventory' THEN CAST(square_feet AS FLOAT) END) AS avg_inventory_sqft,
    AVG(CASE WHEN LOWER(record_type) = 'plan' THEN CAST(square_feet AS FLOAT) END) AS avg_plan_sqft,
    AVG(CASE WHEN LOWER(record_type) = 'inventory' THEN price_per_sqft END) AS avg_inventory_ppsf,
    AVG(CASE WHEN LOWER(record_type) = 'plan' THEN price_per_sqft END) AS avg_plan_ppsf,
    MIN(CASE WHEN LOWER(record_type) = 'inventory' THEN price END) AS min_inventory_price,
    MAX(CASE WHEN LOWER(record_type) = 'inventory' THEN price END) AS max_inventory_price,
    COUNT(DISTINCT builder_name) AS builder_count
FROM {{ ref('competitor_listing_obt') }}
GROUP BY
    community_key,
    side
