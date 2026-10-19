{{ config(materialized='view', schema='analytics', alias='web_listing_obt') }}

-- Current web listing snapshot for operations reports.
-- Grain: one row per builder listing identity on the latest ingest.
-- Source is warehouse_stage.raw.web_listing_det (scrape notebook).

WITH ranked AS (
    SELECT
        d.*,
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
        'TX' AS state,
        'United States' AS country,
        ROW_NUMBER() OVER (
            PARTITION BY
                COALESCE(d.source_group, ''),
                COALESCE(d.source_name, ''),
                COALESCE(d.record_type, ''),
                COALESCE(
                    d.listing_url,
                    d.plan_url,
                    d.address,
                    d.plan_name,
                    d.plan_number,
                    ''
                )
            ORDER BY d.ingested_at DESC, d.run_id DESC
        ) AS rn
    FROM {{ source('raw', 'web_listing_det') }} d
)
SELECT
    CONVERT(VARCHAR(64), HASHBYTES(
        'SHA2_256',
        CONCAT(
            COALESCE(source_group, ''), '|',
            COALESCE(source_name, ''), '|',
            COALESCE(record_type, ''), '|',
            COALESCE(listing_url, plan_url, address, plan_name, plan_number, '')
        )
    ), 2) AS listing_key,
    builder_name,
    community_name,
    city,
    state,
    country,
    CASE
        WHEN address IS NOT NULL AND city IS NOT NULL
            THEN CONCAT(address, ', ', city, ', ', state, ', ', country)
        WHEN city IS NOT NULL
            THEN CONCAT(COALESCE(community_name, ''), ', ', city, ', ', state, ', ', country)
        ELSE NULL
    END AS map_location,
    record_type,
    availability_status,
    CASE
        WHEN LOWER(COALESCE(availability_status, '')) LIKE '%sold%' THEN 'Sold'
        WHEN LOWER(COALESCE(record_type, '')) = 'plan' THEN 'Plan'
        ELSE 'Available'
    END AS availability_group,
    plan_name,
    elevation,
    plan_number,
    price,
    starting_price,
    COALESCE(price, starting_price) AS display_price,
    CASE
        WHEN square_feet IS NOT NULL AND square_feet > 0
             AND COALESCE(price, starting_price) IS NOT NULL
            THEN CAST(COALESCE(price, starting_price) AS FLOAT)
                 / CAST(square_feet AS FLOAT)
        ELSE NULL
    END AS price_per_sqft,
    square_feet,
    bedrooms,
    bathrooms,
    stories,
    garage_spaces,
    lot_size,
    address,
    estimated_move_in_date,
    listing_url,
    plan_url,
    CASE
        WHEN LOWER(COALESCE(record_type, '')) = 'inventory'
             AND address IS NOT NULL
            THEN 'Y'
        ELSE 'N'
    END AS is_mappable,
    run_id,
    ingest_date,
    ingested_at,
    scraper,
    source_name,
    source_group,
    fill_source,
    fill_ingest_date
FROM ranked
WHERE rn = 1
