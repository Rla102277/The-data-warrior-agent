{{ config(materialized='view', schema='analytics', alias='market_dim_community') }}

-- Shared community filter dimension for Market Intelligence (synced slicers).
-- Collapse case variants so Power BI one-side keys stay unique.

SELECT
    MIN(community_name) AS community_name
FROM (
    SELECT community_name FROM {{ ref('competitor_listing_obt') }}
    UNION ALL
    SELECT community_name FROM {{ ref('competitor_position_obt') }}
    UNION ALL
    SELECT community_name FROM {{ ref('web_listing_change_det') }}
    UNION ALL
    SELECT community_name FROM {{ ref('web_scrape_coverage_obt') }}
    UNION ALL
    SELECT community_name FROM {{ ref('competitor_community_obt') }}
) x
WHERE NULLIF(LTRIM(RTRIM(COALESCE(community_name, ''))), '') IS NOT NULL
GROUP BY LOWER(LTRIM(RTRIM(community_name)))
