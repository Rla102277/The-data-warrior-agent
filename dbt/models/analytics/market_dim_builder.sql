{{ config(materialized='view', schema='analytics', alias='market_dim_builder') }}

-- Shared builder filter dimension for Market Intelligence (synced slicers).
-- Collapse case variants so Power BI one-side keys stay unique.

SELECT
    MIN(builder_name) AS builder_name
FROM (
    SELECT builder_name FROM {{ ref('competitor_listing_obt') }}
    UNION ALL
    SELECT builder_name FROM {{ ref('competitor_position_obt') }}
    UNION ALL
    SELECT builder_name FROM {{ ref('web_listing_change_det') }}
    UNION ALL
    SELECT builder_name FROM {{ ref('web_scrape_coverage_obt') }}
    UNION ALL
    SELECT builder_name FROM {{ ref('competitor_peer_obt') }}
) x
WHERE NULLIF(LTRIM(RTRIM(COALESCE(builder_name, ''))), '') IS NOT NULL
GROUP BY LOWER(LTRIM(RTRIM(builder_name)))
