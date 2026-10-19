{{ config(materialized='view', schema='analytics', alias='market_dim_gbp_benchmark') }}

/*
  Selectable GBP benchmark communities for Peer Arena.
  Disconnected dim in the semantic model; DAX measures read SELECTEDVALUE.
*/

SELECT
    MIN(community_name) AS gbp_community_name,
    MIN(source_group) AS gbp_source_group
FROM (
    SELECT
        community_name,
        source_group
    FROM {{ ref('competitor_listing_obt') }}
    WHERE LOWER(COALESCE(side, '')) IN ('gbp_web', 'gbp_erp')
      AND NULLIF(LTRIM(RTRIM(COALESCE(community_name, ''))), '') IS NOT NULL

    UNION ALL

    SELECT
        m.community_name,
        m.source_group
    FROM {{ source('control', 'web_community_project_map') }} AS m
    WHERE m.is_active = 1
      AND NULLIF(LTRIM(RTRIM(COALESCE(m.community_name, ''))), '') IS NOT NULL
) x
GROUP BY LOWER(LTRIM(RTRIM(community_name)))
