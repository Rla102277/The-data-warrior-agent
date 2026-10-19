{{ config(materialized='view', schema='analytics', alias='competitor_price_trend_obt') }}

/*
  Daily competitive pricing trend from append-only raw.web_listing_det.
  Grain: ingest_date + source_group + community + normalized builder.
  Keeps website list / starting price history for Peer Arena trend visuals.
  Price basis is website_list (not ERP SGM).
  City/state are derived the same way as web_listing_obt (raw has no geo cols).
*/

WITH base AS (
    SELECT
        d.ingest_date,
        d.source_group,
        d.community_name,
        CASE d.source_group
            WHEN 'bridgewater-midlothian' THEN 'Midlothian'
            WHEN 'village-at-midtowne' THEN 'Midlothian'
            WHEN 'perry-homes-bridgewater' THEN
                CASE
                    WHEN LOWER(COALESCE(d.listing_url, '')) LIKE '%midlothian%'
                      OR LOWER(COALESCE(d.community_name, '')) LIKE '%midlothian%'
                        THEN 'Midlothian'
                    ELSE 'Dallas'
                END
            WHEN 'star-trail-prosper' THEN 'Prosper'
            WHEN 'phillips-creek-ranch' THEN 'Frisco'
            ELSE NULL
        END AS city,
        CAST('TX' AS VARCHAR(16)) AS state,
        CASE
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%trophy%' THEN 'Trophy'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%meritage%' THEN 'Meritage'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%american legend%'
              OR LOWER(COALESCE(d.builder_name, '')) = 'alh' THEN 'American Legend'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%john houston%'
              OR LOWER(COALESCE(d.builder_name, '')) IN ('jh', 'j houston') THEN 'John Houston'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%tri pointe%'
              OR LOWER(COALESCE(d.builder_name, '')) LIKE '%tripointe%' THEN 'Tri Pointe'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%highland%' THEN 'Highland'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%ashton%' THEN 'Ashton Woods'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%perry%' THEN 'Perry Homes'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%coventry%' THEN 'Coventry'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%britton%' THEN 'Britton'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%tradition%' THEN 'Tradition'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%lennar%' THEN 'Lennar'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%mattamy%' THEN 'Mattamy'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%mi homes%'
              OR LOWER(COALESCE(d.builder_name, '')) = 'mi' THEN 'MI'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%union%main%'
              OR LOWER(COALESCE(d.builder_name, '')) = 'um' THEN 'UM'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%pulte%' THEN 'Pulte'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%horton%' THEN 'Horton'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%khov%'
              OR LOWER(COALESCE(d.builder_name, '')) LIKE '%hovnanian%' THEN 'Khov'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%cb jeni%'
              OR LOWER(COALESCE(d.builder_name, '')) LIKE '%cbjeni%'
              OR LOWER(COALESCE(d.builder_name, '')) = 'cbj' THEN 'CB JENI'
            WHEN LOWER(COALESCE(d.builder_name, '')) LIKE '%toll%' THEN 'Toll Brothers'
            ELSE COALESCE(d.builder_name, '(unknown)')
        END AS builder_name,
        COALESCE(d.price, d.starting_price) AS list_price,
        d.square_feet,
        CASE
            WHEN d.square_feet IS NOT NULL AND d.square_feet > 0
                 AND COALESCE(d.price, d.starting_price) IS NOT NULL
                THEN CAST(COALESCE(d.price, d.starting_price) AS FLOAT)
                     / CAST(d.square_feet AS FLOAT)
            ELSE NULL
        END AS price_per_sqft,
        d.bedrooms,
        d.availability_status,
        CASE
            WHEN LOWER(COALESCE(d.availability_status, '')) LIKE '%sold%' THEN 'Sold'
            WHEN LOWER(COALESCE(d.record_type, '')) = 'plan' THEN 'Plan'
            ELSE 'Available'
        END AS availability_group,
        d.record_type
    FROM {{ source('raw', 'web_listing_det') }} d
    WHERE LOWER(COALESCE(d.record_type, '')) IN ('inventory', 'plan')
      AND NULLIF(LTRIM(RTRIM(COALESCE(d.community_name, ''))), '') IS NOT NULL
),
daily AS (
    SELECT
        ingest_date,
        source_group,
        community_name,
        MAX(city) AS city,
        MAX(state) AS state,
        builder_name,
        SUM(CASE WHEN LOWER(COALESCE(record_type, '')) = 'inventory' THEN 1 ELSE 0 END)
            AS inventory_count,
        SUM(CASE WHEN LOWER(COALESCE(record_type, '')) = 'plan' THEN 1 ELSE 0 END)
            AS plan_count,
        SUM(CASE
            WHEN LOWER(COALESCE(record_type, '')) = 'inventory'
             AND LOWER(COALESCE(availability_group, '')) = 'available'
            THEN 1 ELSE 0
        END) AS available_inventory_count,
        AVG(CASE WHEN LOWER(COALESCE(record_type, '')) = 'inventory'
                 THEN CAST(list_price AS FLOAT) END) AS avg_list_price,
        AVG(CASE WHEN LOWER(COALESCE(record_type, '')) = 'inventory'
                 THEN price_per_sqft END) AS avg_ppsf,
        MIN(CASE WHEN LOWER(COALESCE(record_type, '')) = 'inventory'
                 THEN list_price END) AS min_list_price,
        MAX(CASE WHEN LOWER(COALESCE(record_type, '')) = 'inventory'
                 THEN list_price END) AS max_list_price,
        AVG(CASE WHEN LOWER(COALESCE(record_type, '')) = 'inventory'
                 THEN CAST(square_feet AS FLOAT) END) AS avg_sqft,
        AVG(CASE WHEN LOWER(COALESCE(record_type, '')) = 'inventory'
                 THEN CAST(bedrooms AS FLOAT) END) AS avg_beds,
        CAST('website_list' AS VARCHAR(32)) AS price_basis
    FROM base
    GROUP BY
        ingest_date,
        source_group,
        community_name,
        builder_name
)
SELECT
    d.*,
    LAG(d.avg_list_price) OVER (
        PARTITION BY d.source_group, d.community_name, d.builder_name
        ORDER BY d.ingest_date
    ) AS prev_avg_list_price,
    LAG(d.avg_ppsf) OVER (
        PARTITION BY d.source_group, d.community_name, d.builder_name
        ORDER BY d.ingest_date
    ) AS prev_avg_ppsf,
    LAG(d.inventory_count) OVER (
        PARTITION BY d.source_group, d.community_name, d.builder_name
        ORDER BY d.ingest_date
    ) AS prev_inventory_count,
    CASE
        WHEN LAG(d.avg_list_price) OVER (
            PARTITION BY d.source_group, d.community_name, d.builder_name
            ORDER BY d.ingest_date
        ) IS NULL OR LAG(d.avg_list_price) OVER (
            PARTITION BY d.source_group, d.community_name, d.builder_name
            ORDER BY d.ingest_date
        ) = 0
            THEN NULL
        ELSE (d.avg_list_price - LAG(d.avg_list_price) OVER (
            PARTITION BY d.source_group, d.community_name, d.builder_name
            ORDER BY d.ingest_date
        )) / LAG(d.avg_list_price) OVER (
            PARTITION BY d.source_group, d.community_name, d.builder_name
            ORDER BY d.ingest_date
        )
    END AS avg_price_chg_pct,
    -- Prior-ingest deltas (scrape cadence; not calendar-week when runs are sparse)
    d.inventory_count - LAG(d.inventory_count) OVER (
        PARTITION BY d.source_group, d.community_name, d.builder_name
        ORDER BY d.ingest_date
    ) AS inventory_chg,
    CASE
        WHEN LAG(d.inventory_count) OVER (
            PARTITION BY d.source_group, d.community_name, d.builder_name
            ORDER BY d.ingest_date
        ) IS NULL OR LAG(d.inventory_count) OVER (
            PARTITION BY d.source_group, d.community_name, d.builder_name
            ORDER BY d.ingest_date
        ) = 0
            THEN NULL
        ELSE CAST(d.inventory_count - LAG(d.inventory_count) OVER (
            PARTITION BY d.source_group, d.community_name, d.builder_name
            ORDER BY d.ingest_date
        ) AS FLOAT) / CAST(LAG(d.inventory_count) OVER (
            PARTITION BY d.source_group, d.community_name, d.builder_name
            ORDER BY d.ingest_date
        ) AS FLOAT)
    END AS inventory_chg_pct,
    d7.avg_list_price AS avg_list_price_7d_ago,
    d7.inventory_count AS inventory_count_7d_ago,
    CASE
        WHEN d7.avg_list_price IS NULL OR d7.avg_list_price = 0 THEN NULL
        ELSE (d.avg_list_price - d7.avg_list_price) / d7.avg_list_price
    END AS avg_price_wow_pct,
    CASE
        WHEN d7.inventory_count IS NULL OR d7.inventory_count = 0 THEN NULL
        ELSE CAST(d.inventory_count - d7.inventory_count AS FLOAT)
             / CAST(d7.inventory_count AS FLOAT)
    END AS inventory_wow_pct
FROM daily d
LEFT JOIN daily d7
    ON d7.source_group = d.source_group
   AND d7.community_name = d.community_name
   AND d7.builder_name = d.builder_name
   AND d7.ingest_date = DATEADD(day, -7, d.ingest_date)
