{{ config(materialized='view', schema='analytics', alias='competitor_position_obt') }}

/*
  Competitor positioning grain.
  One row per source_group + community + normalized builder + side.
  Competition:
    is_dataverse_peer       = community matches active scanning gbp_communities
    is_peer_project         = community matches a peer project link
                              (gbp_gbppeercommunities via control.web_peer_project)
    is_multi_builder_market = 2+ builders share the community name
    is_competitive_market   = multi-builder OR scanning peer OR peer project
      (proximity miles/tier remain enrichment only)
    Also: available share, plan vs inventory ASP, nearest GBP pricing.
*/

WITH base AS (
    SELECT
        source_group,
        community_name,
        city,
        state,
        side,
        price_basis,
        CASE
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%trophy%'
                THEN 'Trophy'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%meritage%'
                THEN 'Meritage'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%american legend%'
              OR LOWER(COALESCE(builder_name, '')) = 'alh'
                THEN 'American Legend'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%john houston%'
              OR LOWER(COALESCE(builder_name, '')) IN ('jh', 'j houston')
                THEN 'John Houston'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%tri pointe%'
              OR LOWER(COALESCE(builder_name, '')) LIKE '%tripointe%'
                THEN 'Tri Pointe'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%highland%'
                THEN 'Highland'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%ashton%'
                THEN 'Ashton Woods'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%perry%'
                THEN 'Perry Homes'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%coventry%'
                THEN 'Coventry'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%britton%'
                THEN 'Britton'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%tradition%'
                THEN 'Tradition'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%lennar%'
                THEN 'Lennar'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%mattamy%'
                THEN 'Mattamy'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%mi homes%'
              OR LOWER(COALESCE(builder_name, '')) = 'mi'
                THEN 'MI'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%union%main%'
              OR LOWER(COALESCE(builder_name, '')) = 'um'
                THEN 'UM'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%pulte%'
                THEN 'Pulte'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%horton%'
                THEN 'Horton'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%khov%'
              OR LOWER(COALESCE(builder_name, '')) LIKE '%hovnanian%'
                THEN 'Khov'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%cb jeni%'
              OR LOWER(COALESCE(builder_name, '')) LIKE '%cbjeni%'
              OR LOWER(COALESCE(builder_name, '')) = 'cbj'
                THEN 'CB JENI'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%toll%'
                THEN 'Toll Brothers'
            WHEN LOWER(COALESCE(builder_name, '')) LIKE '%gbp erp%'
                THEN 'GBP ERP'
            ELSE COALESCE(builder_name, '(unknown)')
        END AS builder_name,
        record_type,
        price,
        price_per_sqft,
        square_feet,
        bedrooms,
        availability_group
    FROM {{ ref('competitor_listing_obt') }}
    WHERE NULLIF(LTRIM(RTRIM(COALESCE(community_name, ''))), '') IS NOT NULL
),
inv AS (
    SELECT *
    FROM base
    WHERE LOWER(COALESCE(record_type, '')) = 'inventory'
),
plans AS (
    SELECT *
    FROM base
    WHERE LOWER(COALESCE(record_type, '')) = 'plan'
),
agg AS (
    SELECT
        source_group,
        community_name,
        MAX(city) AS city,
        MAX(state) AS state,
        builder_name,
        side,
        MAX(price_basis) AS price_basis,
        COUNT(*) AS inventory_count,
        SUM(CASE WHEN LOWER(COALESCE(availability_group, '')) = 'available' THEN 1 ELSE 0 END)
            AS available_count,
        AVG(CAST(price AS FLOAT)) AS avg_price,
        AVG(price_per_sqft) AS avg_ppsf,
        MIN(price) AS min_price,
        MAX(price) AS max_price,
        AVG(CAST(square_feet AS FLOAT)) AS avg_sqft,
        AVG(CAST(bedrooms AS FLOAT)) AS avg_beds,
        MAX(price) - MIN(price) AS price_spread,
        CASE
            WHEN AVG(CAST(price AS FLOAT)) IS NULL OR AVG(CAST(price AS FLOAT)) = 0 THEN NULL
            ELSE CAST(MAX(price) - MIN(price) AS FLOAT) / AVG(CAST(price AS FLOAT))
        END AS price_spread_pct
    FROM inv
    GROUP BY
        source_group,
        community_name,
        builder_name,
        side
),
plan_agg AS (
    SELECT
        source_group,
        community_name,
        builder_name,
        side,
        AVG(CAST(price AS FLOAT)) AS plan_avg_price,
        AVG(price_per_sqft) AS plan_avg_ppsf,
        COUNT(*) AS plan_count
    FROM plans
    GROUP BY
        source_group,
        community_name,
        builder_name,
        side
),
comm_stats AS (
    SELECT
        source_group,
        community_name,
        COUNT(DISTINCT builder_name) AS builder_count_in_community,
        SUM(inventory_count) AS community_inventory,
        AVG(avg_price) AS community_avg_price,
        AVG(avg_ppsf) AS community_avg_ppsf
    FROM agg
    GROUP BY source_group, community_name
),
nearest_gbp AS (
    SELECT
        peer_source_group AS source_group,
        peer_community_name AS community_name,
        gbp_community_name AS nearest_gbp_community,
        gbp_source_group AS nearest_gbp_source_group,
        miles_to_gbp AS miles_to_nearest_gbp,
        competition_tier,
        is_competitive,
        ROW_NUMBER() OVER (
            PARTITION BY peer_source_group, peer_community_name
            ORDER BY
                CASE competition_tier
                    WHEN 'same_community' THEN 0
                    WHEN 'primary' THEN 1
                    WHEN 'secondary' THEN 2
                    ELSE 3
                END,
                miles_to_gbp ASC
        ) AS rn
    FROM {{ ref('community_proximity_map') }}
    WHERE is_competitive = 1
),
gbp_comm_price AS (
    SELECT
        source_group,
        community_name,
        AVG(avg_price) AS gbp_community_avg_price,
        AVG(avg_ppsf) AS gbp_community_avg_ppsf
    FROM agg
    WHERE LOWER(COALESCE(side, '')) IN ('gbp_web', 'gbp_erp')
    GROUP BY source_group, community_name
),
dv_peers AS (
    SELECT DISTINCT
        LOWER(LTRIM(RTRIM(community_name))) AS community_name_key
    FROM {{ ref('market_peer_community_obt') }}
    WHERE is_active_peer = 1
),
peer_ranked AS (
    SELECT
        LOWER(LTRIM(RTRIM(peer_community_name))) AS peer_community_name_key,
        project_code AS peer_project_code,
        project_name AS peer_project_name,
        operating_unit_code AS peer_operating_unit_code,
        match_score AS peer_match_score,
        ROW_NUMBER() OVER (
            PARTITION BY LOWER(LTRIM(RTRIM(peer_community_name)))
            ORDER BY
                CASE WHEN match_score IS NULL THEN 1 ELSE 0 END,
                match_score DESC,
                project_code
        ) AS rn
    FROM {{ ref('market_peer_project_obt') }}
    WHERE is_active = 1
      AND NULLIF(LTRIM(RTRIM(COALESCE(peer_community_name, ''))), '') IS NOT NULL
),
peer_best AS (
    SELECT
        peer_community_name_key,
        peer_project_code,
        peer_project_name,
        peer_operating_unit_code,
        peer_match_score
    FROM peer_ranked
    WHERE rn = 1
),
scrape_communities AS (
    SELECT DISTINCT
        LOWER(LTRIM(RTRIM(community_name))) AS community_name_key
    FROM agg
),
peer_matched AS (
    SELECT
        s.community_name_key,
        v.peer_project_code,
        v.peer_project_name,
        v.peer_operating_unit_code,
        v.peer_match_score,
        ROW_NUMBER() OVER (
            PARTITION BY s.community_name_key
            ORDER BY
                CASE
                    WHEN v.peer_community_name_key = s.community_name_key THEN 0
                    ELSE 1
                END,
                LEN(v.peer_community_name_key) ASC,
                CASE WHEN v.peer_match_score IS NULL THEN 1 ELSE 0 END,
                v.peer_match_score DESC
        ) AS rn
    FROM scrape_communities s
    INNER JOIN peer_best v
        ON v.peer_community_name_key = s.community_name_key
        OR v.peer_community_name_key LIKE s.community_name_key + ' %'
),
peer_one AS (
    SELECT
        community_name_key,
        peer_project_code,
        peer_project_name,
        peer_operating_unit_code,
        peer_match_score
    FROM peer_matched
    WHERE rn = 1
)
SELECT
    a.source_group,
    a.community_name,
    a.city,
    a.state,
    a.builder_name,
    a.side,
    a.price_basis,
    a.inventory_count,
    a.available_count,
    CASE
        WHEN a.inventory_count IS NULL OR a.inventory_count = 0 THEN NULL
        ELSE CAST(a.available_count AS FLOAT) / CAST(a.inventory_count AS FLOAT)
    END AS available_share,
    a.avg_price,
    a.avg_ppsf,
    a.min_price,
    a.max_price,
    a.avg_sqft,
    a.avg_beds,
    a.price_spread,
    a.price_spread_pct,
    pa.plan_count,
    pa.plan_avg_price,
    pa.plan_avg_ppsf,
    CASE
        WHEN a.avg_price IS NULL OR a.avg_price = 0 OR pa.plan_avg_price IS NULL THEN NULL
        ELSE (a.avg_price - pa.plan_avg_price) / pa.plan_avg_price
    END AS inventory_vs_plan_asp_pct,
    c.builder_count_in_community,
    c.community_inventory,
    c.community_avg_price,
    c.community_avg_ppsf,
    CASE WHEN c.builder_count_in_community >= 2 THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END
        AS is_multi_builder_market,
    CASE
        WHEN dv.community_name_key IS NOT NULL THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
    END AS is_dataverse_peer,
    CASE
        WHEN peer.community_name_key IS NOT NULL THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
    END AS is_peer_project,
    peer.peer_project_code,
    peer.peer_project_name,
    peer.peer_operating_unit_code,
    peer.peer_match_score,
    CASE
        WHEN c.builder_count_in_community >= 2
          OR dv.community_name_key IS NOT NULL
          OR peer.community_name_key IS NOT NULL
            THEN CAST(1 AS BIT)
        ELSE CAST(0 AS BIT)
    END AS is_competitive_market,
    n.competition_tier,
    n.miles_to_nearest_gbp,
    n.nearest_gbp_community,
    n.nearest_gbp_source_group,
    gp.gbp_community_avg_price AS nearest_gbp_avg_price,
    gp.gbp_community_avg_ppsf AS nearest_gbp_avg_ppsf,
    CASE
        WHEN gp.gbp_community_avg_price IS NULL OR gp.gbp_community_avg_price = 0
             OR a.avg_price IS NULL
            THEN NULL
        ELSE (a.avg_price - gp.gbp_community_avg_price) / gp.gbp_community_avg_price
    END AS price_vs_nearest_gbp_pct,
    CASE
        WHEN gp.gbp_community_avg_ppsf IS NULL OR gp.gbp_community_avg_ppsf = 0
             OR a.avg_ppsf IS NULL
            THEN NULL
        ELSE (a.avg_ppsf - gp.gbp_community_avg_ppsf) / gp.gbp_community_avg_ppsf
    END AS ppsf_vs_nearest_gbp_pct,
    CASE
        WHEN c.community_inventory IS NULL OR c.community_inventory = 0 THEN NULL
        ELSE CAST(a.inventory_count AS FLOAT) / CAST(c.community_inventory AS FLOAT)
    END AS inventory_share,
    CASE
        WHEN c.community_avg_price IS NULL OR c.community_avg_price = 0 OR a.avg_price IS NULL
            THEN NULL
        ELSE (a.avg_price - c.community_avg_price) / c.community_avg_price
    END AS price_vs_community_pct,
    CASE
        WHEN c.community_avg_ppsf IS NULL OR c.community_avg_ppsf = 0 OR a.avg_ppsf IS NULL
            THEN NULL
        ELSE (a.avg_ppsf - c.community_avg_ppsf) / c.community_avg_ppsf
    END AS ppsf_vs_community_pct,
    CASE
        WHEN a.avg_ppsf IS NULL THEN CAST(NULL AS INT)
        ELSE RANK() OVER (
            PARTITION BY a.source_group, a.community_name, a.side
            ORDER BY a.avg_ppsf ASC
        )
    END AS ppsf_rank_asc,
    CASE
        WHEN a.avg_price IS NULL THEN CAST(NULL AS INT)
        ELSE RANK() OVER (
            PARTITION BY a.source_group, a.community_name, a.side
            ORDER BY a.avg_price ASC
        )
    END AS price_rank_asc
FROM agg a
INNER JOIN comm_stats c
    ON c.source_group = a.source_group
   AND c.community_name = a.community_name
LEFT JOIN plan_agg pa
    ON pa.source_group = a.source_group
   AND pa.community_name = a.community_name
   AND pa.builder_name = a.builder_name
   AND pa.side = a.side
LEFT JOIN nearest_gbp n
    ON n.source_group = a.source_group
   AND n.community_name = a.community_name
   AND n.rn = 1
LEFT JOIN gbp_comm_price gp
    ON gp.source_group = n.nearest_gbp_source_group
   AND gp.community_name = n.nearest_gbp_community
LEFT JOIN dv_peers dv
    ON dv.community_name_key = LOWER(LTRIM(RTRIM(a.community_name)))
LEFT JOIN peer_one peer
    ON peer.community_name_key = LOWER(LTRIM(RTRIM(a.community_name)))
