{{ config(materialized='view', schema='analytics', alias='competitor_listing_obt') }}

-- Listing-level competitor analysis grain.
-- side: competitor_web | gbp_web | gbp_erp
-- Website price = display_price. GBP ERP price = SGM base_revenue / plan base_price.
-- Not dbo.

WITH gbp AS (
    SELECT LOWER(builder_alias) AS alias
    FROM {{ source('control', 'web_gbp_builder') }}
    WHERE is_active = 1
),
web AS (
    SELECT
        w.listing_key,
        CONVERT(VARCHAR(64), HASHBYTES(
            'SHA2_256',
            CONCAT(COALESCE(w.source_group, ''), '|', COALESCE(w.community_name, ''))
        ), 2) AS community_key,
        w.source_group,
        w.source_name,
        w.community_name,
        w.city,
        w.state,
        w.country,
        w.builder_name,
        CASE
            WHEN EXISTS (
                SELECT 1 FROM gbp g
                WHERE LOWER(COALESCE(w.builder_name, '')) LIKE '%' + g.alias + '%'
                   OR g.alias LIKE '%' + LOWER(COALESCE(w.builder_name, '')) + '%'
            ) THEN 'gbp_web'
            ELSE 'competitor_web'
        END AS side,
        w.record_type,
        w.availability_status,
        w.availability_group,
        w.address,
        w.plan_name,
        w.plan_number,
        w.elevation,
        w.display_price AS price,
        w.square_feet,
        CASE
            WHEN w.square_feet IS NOT NULL AND w.square_feet > 0
                 AND w.display_price IS NOT NULL
                THEN CAST(w.display_price AS FLOAT) / CAST(w.square_feet AS FLOAT)
            ELSE NULL
        END AS price_per_sqft,
        w.bedrooms,
        w.bathrooms,
        w.stories,
        w.garage_spaces,
        w.listing_url,
        w.plan_url,
        w.ingest_date,
        w.ingested_at,
        CAST(NULL AS VARCHAR(32)) AS project_id,
        CAST(NULL AS VARCHAR(256)) AS project_name,
        'website_list' AS price_basis
    FROM {{ ref('web_listing_obt') }} w
    WHERE LOWER(COALESCE(w.record_type, '')) IN ('inventory', 'plan')
),
erp_lots AS (
    SELECT
        CONVERT(VARCHAR(64), HASHBYTES(
            'SHA2_256',
            CONCAT('gbp_erp|lot|', COALESCE(l.lot_id, ''))
        ), 2) AS listing_key,
        CONVERT(VARCHAR(64), HASHBYTES(
            'SHA2_256',
            CONCAT(COALESCE(m.source_group, ''), '|', COALESCE(m.community_name, ''))
        ), 2) AS community_key,
        m.source_group,
        CAST(NULL AS VARCHAR(64)) AS source_name,
        m.community_name,
        l.city,
        l.state,
        CAST('United States' AS VARCHAR(64)) AS country,
        COALESCE(l.operating_unit_name, 'GBP ERP') AS builder_name,
        CAST('gbp_erp' AS VARCHAR(32)) AS side,
        CAST('inventory' AS VARCHAR(32)) AS record_type,
        l.lot_status AS availability_status,
        CASE
            WHEN l.is_closed = 1 OR LOWER(COALESCE(l.lot_status, '')) LIKE '%closed%'
                THEN 'Sold'
            ELSE 'Available'
        END AS availability_group,
        COALESCE(l.street, l.lot_label, l.lot_number) AS address,
        COALESCE(l.plan_description, l.plan_code) AS plan_name,
        l.plan_code AS plan_number,
        l.elevation,
        CAST(f.base_revenue AS INT) AS price,
        COALESCE(f.sqft, l.base_square_footage) AS square_feet,
        CASE
            WHEN COALESCE(f.sqft, l.base_square_footage) IS NOT NULL
                 AND COALESCE(f.sqft, l.base_square_footage) > 0
                 AND f.base_revenue IS NOT NULL
                THEN CAST(f.base_revenue AS FLOAT)
                     / CAST(COALESCE(f.sqft, l.base_square_footage) AS FLOAT)
            ELSE NULL
        END AS price_per_sqft,
        CAST(NULL AS INT) AS bedrooms,
        CAST(NULL AS DECIMAL(6, 2)) AS bathrooms,
        CAST(NULL AS INT) AS stories,
        CAST(NULL AS INT) AS garage_spaces,
        CAST(NULL AS VARCHAR(1000)) AS listing_url,
        CAST(NULL AS VARCHAR(1000)) AS plan_url,
        CAST(NULL AS DATE) AS ingest_date,
        CAST(NULL AS DATETIME2(0)) AS ingested_at,
        m.project_id,
        m.project_name,
        CAST('sgm_base_revenue' AS VARCHAR(32)) AS price_basis
    FROM {{ source('control', 'web_community_project_map') }} m
    INNER JOIN {{ ref('lot_obt') }} l
        ON l.project_id = m.project_id
    LEFT JOIN {{ ref('lot_financials_obt') }} f
        ON f.lot_id = l.lot_id
    WHERE m.is_active = 1
      AND COALESCE(l.exclude_from_reporting, 0) = 0
),
erp_plans AS (
    SELECT
        CONVERT(VARCHAR(64), HASHBYTES(
            'SHA2_256',
            CONCAT(
                'gbp_erp|plan|',
                COALESCE(m.project_id, ''), '|',
                COALESCE(p.plan_code, ''), '|',
                COALESCE(p.elev, '')
            )
        ), 2) AS listing_key,
        CONVERT(VARCHAR(64), HASHBYTES(
            'SHA2_256',
            CONCAT(COALESCE(m.source_group, ''), '|', COALESCE(m.community_name, ''))
        ), 2) AS community_key,
        m.source_group,
        CAST(NULL AS VARCHAR(64)) AS source_name,
        m.community_name,
        CAST(NULL AS VARCHAR(64)) AS city,
        CAST('TX' AS VARCHAR(16)) AS state,
        CAST('United States' AS VARCHAR(64)) AS country,
        CAST('GBP ERP' AS VARCHAR(128)) AS builder_name,
        CAST('gbp_erp' AS VARCHAR(32)) AS side,
        CAST('plan' AS VARCHAR(32)) AS record_type,
        CASE WHEN p.active = 1 THEN 'Available' ELSE 'Inactive' END AS availability_status,
        CAST('Plan' AS VARCHAR(32)) AS availability_group,
        CAST(NULL AS VARCHAR(256)) AS address,
        p.plan_name,
        p.plan_code AS plan_number,
        p.elev AS elevation,
        CAST(p.base_price AS INT) AS price,
        p.square_footage AS square_feet,
        CASE
            WHEN p.square_footage IS NOT NULL AND p.square_footage > 0
                 AND p.base_price IS NOT NULL AND p.base_price > 0
                THEN CAST(p.base_price AS FLOAT) / CAST(p.square_footage AS FLOAT)
            ELSE NULL
        END AS price_per_sqft,
        p.bedrooms,
        CAST(p.full_bathrooms AS DECIMAL(6, 2)) AS bathrooms,
        p.stories,
        p.garage_spaces,
        CAST(NULL AS VARCHAR(1000)) AS listing_url,
        CAST(NULL AS VARCHAR(1000)) AS plan_url,
        CAST(NULL AS DATE) AS ingest_date,
        CAST(NULL AS DATETIME2(0)) AS ingested_at,
        m.project_id,
        m.project_name,
        CAST('plan_base_price' AS VARCHAR(32)) AS price_basis
    FROM {{ source('control', 'web_community_project_map') }} m
    INNER JOIN {{ ref('plan') }} p
        ON p.project_id = m.project_id
    WHERE m.is_active = 1
      AND COALESCE(p.base_price, 0) > 0
)
SELECT * FROM web
UNION ALL
SELECT * FROM erp_lots
UNION ALL
SELECT * FROM erp_plans
