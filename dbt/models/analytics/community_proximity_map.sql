{{ config(materialized='view', schema='analytics', alias='community_proximity_map') }}

/*
  Proximity competitive set around Green Brick (GBP) communities.
  Grain: gbp_source_group + gbp_community_name + peer_source_group + peer_community_name.
  Tiers: same_community | primary (<=3 mi) | secondary (<=5 mi) | out_of_ring.
  Miles = great-circle on control.web_community_geo centroids.
*/

WITH geo AS (
    SELECT
        source_group,
        community_name,
        city,
        state,
        latitude,
        longitude,
        geo_method,
        geo_confidence,
        CAST(is_gbp_focal AS INT) AS is_gbp_focal
    FROM {{ source('control', 'web_community_geo') }}
    WHERE LOWER(COALESCE(geo_confidence, '')) IN ('high', 'medium')
),
gbp AS (
    SELECT *
    FROM geo
    WHERE is_gbp_focal = 1
),
peer AS (
    SELECT *
    FROM geo
),
pairs AS (
    SELECT
        g.source_group AS gbp_source_group,
        g.community_name AS gbp_community_name,
        g.city AS gbp_city,
        g.latitude AS gbp_latitude,
        g.longitude AS gbp_longitude,
        p.source_group AS peer_source_group,
        p.community_name AS peer_community_name,
        p.city AS peer_city,
        p.latitude AS peer_latitude,
        p.longitude AS peer_longitude,
        p.is_gbp_focal AS peer_is_gbp,
        p.geo_confidence AS peer_geo_confidence,
        g.geo_confidence AS gbp_geo_confidence,
        CAST(
            3958.7613 * 2.0 * ASIN(SQRT(
                POWER(SIN(RADIANS((p.latitude - g.latitude) / 2.0)), 2)
                + COS(RADIANS(g.latitude)) * COS(RADIANS(p.latitude))
                  * POWER(SIN(RADIANS((p.longitude - g.longitude) / 2.0)), 2)
            ))
        AS FLOAT) AS miles_to_gbp,
        CASE
            WHEN LOWER(LTRIM(RTRIM(p.community_name))) = LOWER(LTRIM(RTRIM(g.community_name)))
                THEN 1
            ELSE 0
        END AS is_same_community_name
    FROM gbp g
    INNER JOIN peer p
        ON NOT (
            p.source_group = g.source_group
            AND p.community_name = g.community_name
        )
),
scrape_peers AS (
    SELECT DISTINCT
        source_group,
        community_name
    FROM {{ ref('competitor_listing_obt') }}
    WHERE LOWER(COALESCE(record_type, '')) = 'inventory'
      AND NULLIF(LTRIM(RTRIM(COALESCE(community_name, ''))), '') IS NOT NULL
)
SELECT
    pr.gbp_source_group,
    pr.gbp_community_name,
    pr.gbp_city,
    pr.gbp_latitude,
    pr.gbp_longitude,
    pr.peer_source_group,
    pr.peer_community_name,
    pr.peer_city,
    pr.peer_latitude,
    pr.peer_longitude,
    pr.peer_is_gbp,
    pr.peer_geo_confidence,
    pr.gbp_geo_confidence,
    pr.miles_to_gbp,
    CAST(pr.is_same_community_name AS BIT) AS is_same_community_name,
    CASE
        WHEN pr.is_same_community_name = 1 THEN 'same_community'
        WHEN pr.miles_to_gbp <= 3.0 THEN 'primary'
        WHEN pr.miles_to_gbp <= 5.0 THEN 'secondary'
        ELSE 'out_of_ring'
    END AS competition_tier,
    CASE
        WHEN pr.is_same_community_name = 1
          OR pr.miles_to_gbp <= 5.0
            THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
    END AS is_competitive,
    CASE
        WHEN s.source_group IS NOT NULL THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
    END AS peer_has_scrape_inventory
FROM pairs pr
LEFT JOIN scrape_peers s
    ON s.source_group = pr.peer_source_group
   AND LOWER(LTRIM(RTRIM(s.community_name))) = LOWER(LTRIM(RTRIM(pr.peer_community_name)))
