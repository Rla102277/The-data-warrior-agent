{{ config(materialized='view', schema='analytics', alias='market_peer_community_obt') }}

/*
  Active Dataverse peer communities (gbp_communities) for Market Intelligence.
  Same membership contract as control.sp_sync_web_scrape_from_dataverse:
    scanningallowed=1, statecode=0, not deleted.
  Scrape match is enrichment (name or control.web_scrape_source).
*/

WITH peers AS (
    SELECT
        CAST(c.gbp_communitiesid AS VARCHAR(64)) AS community_id,
        LTRIM(RTRIM(c.gbp_name)) AS community_name,
        LTRIM(RTRIM(COALESCE(NULLIF(b.gbp_name, ''), c.gbp_brandname))) AS builder_name,
        LTRIM(RTRIM(c.gbp_listingsurl)) AS listings_url,
        LTRIM(RTRIM(c.gbp_plansurl)) AS plans_url,
        CAST(c.gbp_scanlistings AS INT) AS scan_listings,
        CAST(c.gbp_scanplans AS INT) AS scan_plans,
        CAST(1 AS BIT) AS is_active_peer
    FROM {{ source('dataverse', 'gbp_communities') }} AS c
    LEFT JOIN {{ source('dataverse', 'gbp_brands') }} AS b
        ON b.gbp_brandsid = c.gbp_brand
       AND ISNULL(b.IsDelete, 0) = 0
    WHERE CAST(c.gbp_scanningallowed AS INT) = 1
      AND ISNULL(c.IsDelete, 0) = 0
      AND ISNULL(c.statecode, 0) = 0
      AND NULLIF(LTRIM(RTRIM(c.gbp_name)), '') IS NOT NULL
),
scrape_by_name AS (
    SELECT
        LOWER(LTRIM(RTRIM(community_name))) AS community_name_key,
        MIN(source_group) AS matched_source_group,
        CAST(1 AS BIT) AS has_scrape_data
    FROM {{ ref('competitor_listing_obt') }}
    WHERE NULLIF(LTRIM(RTRIM(COALESCE(community_name, ''))), '') IS NOT NULL
    GROUP BY LOWER(LTRIM(RTRIM(community_name)))
),
scrape_by_source AS (
    SELECT
        LOWER(LTRIM(RTRIM(community_name))) AS community_name_key,
        MIN(source_group) AS matched_source_group,
        CAST(1 AS BIT) AS has_scrape_data
    FROM {{ source('control', 'web_scrape_source') }}
    WHERE is_active = 1
      AND NULLIF(LTRIM(RTRIM(COALESCE(community_name, ''))), '') IS NOT NULL
    GROUP BY LOWER(LTRIM(RTRIM(community_name)))
)
SELECT
    p.community_id,
    p.community_name,
    p.builder_name,
    p.listings_url,
    p.plans_url,
    p.scan_listings,
    p.scan_plans,
    p.is_active_peer,
    CAST(COALESCE(n.has_scrape_data, s.has_scrape_data, 0) AS BIT) AS has_scrape_data,
    COALESCE(n.matched_source_group, s.matched_source_group) AS matched_source_group
FROM peers p
LEFT JOIN scrape_by_name n
    ON n.community_name_key = LOWER(LTRIM(RTRIM(p.community_name)))
LEFT JOIN scrape_by_source s
    ON s.community_name_key = LOWER(LTRIM(RTRIM(p.community_name)))
       AND n.community_name_key IS NULL
