{{ config(materialized='view', schema='analytics', alias='market_peer_project_obt') }}

/*
  Peer project links for Market Intelligence Peer Arena.
  Competitor community <-> GBP project stamps (code / name / OU).
  Source: control.web_peer_project (API land of gbp_gbppeercommunities).
  Grain: one row per peer_link_id.
*/

WITH links AS (
    SELECT
        peer_link_id,
        link_name,
        peer_community_id,
        LTRIM(RTRIM(peer_community_name)) AS peer_community_name,
        internal_project_id,
        LTRIM(RTRIM(internal_project_label)) AS internal_project_label,
        LTRIM(RTRIM(project_code)) AS project_code,
        LTRIM(RTRIM(project_name)) AS project_name,
        LTRIM(RTRIM(operating_unit_code)) AS operating_unit_code,
        match_score,
        match_reasons,
        match_source,
        match_run_id,
        CAST(is_active AS BIT) AS is_active,
        synced_at
    FROM {{ source('control', 'web_peer_project') }}
    WHERE is_active = 1
      AND NULLIF(LTRIM(RTRIM(COALESCE(peer_community_name, ''))), '') IS NOT NULL
),
dv_comm AS (
    SELECT
        CAST(c.gbp_communitiesid AS VARCHAR(64)) AS community_id,
        LTRIM(RTRIM(c.gbp_name)) AS community_name,
        LTRIM(RTRIM(COALESCE(NULLIF(b.gbp_name, ''), c.gbp_brandname))) AS builder_name,
        LTRIM(RTRIM(c.gbp_listingsurl)) AS listings_url,
        LTRIM(RTRIM(c.gbp_plansurl)) AS plans_url,
        CAST(c.gbp_scanlistings AS INT) AS scan_listings,
        CAST(c.gbp_scanplans AS INT) AS scan_plans,
        CAST(c.gbp_scanningallowed AS INT) AS scanning_allowed
    FROM {{ source('dataverse', 'gbp_communities') }} AS c
    LEFT JOIN {{ source('dataverse', 'gbp_brands') }} AS b
        ON b.gbp_brandsid = c.gbp_brand
       AND ISNULL(b.IsDelete, 0) = 0
    WHERE ISNULL(c.IsDelete, 0) = 0
      AND ISNULL(c.statecode, 0) = 0
),
scrape_by_name AS (
    SELECT
        LOWER(LTRIM(RTRIM(community_name))) AS community_name_key,
        MIN(source_group) AS matched_source_group,
        CAST(1 AS BIT) AS has_scrape_data
    FROM {{ ref('competitor_listing_obt') }}
    WHERE NULLIF(LTRIM(RTRIM(COALESCE(community_name, ''))), '') IS NOT NULL
    GROUP BY LOWER(LTRIM(RTRIM(community_name)))
)
SELECT
    l.peer_link_id,
    l.link_name,
    COALESCE(d.community_id, d_by_name.community_id, l.peer_community_id) AS peer_community_id,
    l.peer_community_name,
    COALESCE(d.builder_name, d_by_name.builder_name) AS peer_builder_name,
    COALESCE(d.listings_url, d_by_name.listings_url) AS listings_url,
    COALESCE(d.plans_url, d_by_name.plans_url) AS plans_url,
    COALESCE(d.scan_listings, d_by_name.scan_listings) AS scan_listings,
    COALESCE(d.scan_plans, d_by_name.scan_plans) AS scan_plans,
    CAST(CASE
        WHEN COALESCE(d.scanning_allowed, d_by_name.scanning_allowed) = 1 THEN 1
        ELSE 0
    END AS BIT) AS is_scanning_allowed,
    l.internal_project_id,
    l.internal_project_label,
    l.project_code,
    l.project_name,
    l.operating_unit_code,
    l.match_score,
    l.match_reasons,
    l.match_source,
    l.match_run_id,
    l.is_active,
    CAST(COALESCE(s.has_scrape_data, 0) AS BIT) AS has_scrape_data,
    s.matched_source_group,
    l.synced_at
FROM links l
LEFT JOIN dv_comm d
    ON d.community_id = l.peer_community_id
LEFT JOIN dv_comm d_by_name
    ON d.community_id IS NULL
   AND LOWER(LTRIM(RTRIM(d_by_name.community_name)))
     = LOWER(LTRIM(RTRIM(l.peer_community_name)))
LEFT JOIN scrape_by_name s
    ON s.community_name_key = LOWER(LTRIM(RTRIM(l.peer_community_name)))
