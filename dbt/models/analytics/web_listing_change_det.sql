{{ config(materialized='view', schema='analytics', alias='web_listing_change_det') }}

-- Listing change events between snapshot dates.
-- Grain: one event per listing_key + ingest_date change observation.

WITH base AS (
    SELECT
        CONVERT(VARCHAR(64), HASHBYTES(
            'SHA2_256',
            CONCAT(
                COALESCE(d.source_group, ''), '|',
                COALESCE(d.source_name, ''), '|',
                COALESCE(d.record_type, ''), '|',
                COALESCE(
                    d.listing_url,
                    d.plan_url,
                    d.address,
                    d.plan_name,
                    d.plan_number,
                    ''
                )
            )
        ), 2) AS listing_key,
        CONVERT(VARCHAR(64), HASHBYTES(
            'SHA2_256',
            CONCAT(
                COALESCE(d.builder_name, ''), '|',
                COALESCE(d.community_name, ''), '|',
                COALESCE(d.record_type, ''), '|',
                COALESCE(d.plan_name, ''), '|',
                COALESCE(d.elevation, ''), '|',
                COALESCE(d.plan_number, ''), '|',
                COALESCE(CONVERT(VARCHAR(32), d.price), ''), '|',
                COALESCE(CONVERT(VARCHAR(32), d.starting_price), ''), '|',
                COALESCE(CONVERT(VARCHAR(32), d.square_feet), ''), '|',
                COALESCE(CONVERT(VARCHAR(32), d.bedrooms), ''), '|',
                COALESCE(CONVERT(VARCHAR(32), d.bathrooms), ''), '|',
                COALESCE(CONVERT(VARCHAR(32), d.stories), ''), '|',
                COALESCE(CONVERT(VARCHAR(32), d.garage_spaces), ''), '|',
                COALESCE(d.lot_size, ''), '|',
                COALESCE(d.address, ''), '|',
                COALESCE(d.availability_status, ''), '|',
                COALESCE(d.estimated_move_in_date, ''), '|',
                COALESCE(d.listing_url, ''), '|',
                COALESCE(d.plan_url, '')
            )
        ), 2) AS content_hash,
        d.*
    FROM {{ source('raw', 'web_listing_det') }} d
),
daily AS (
    SELECT *
    FROM (
        SELECT
            b.*,
            ROW_NUMBER() OVER (
                PARTITION BY b.listing_key, b.ingest_date
                ORDER BY b.ingested_at DESC, b.run_id DESC
            ) AS rn
        FROM base b
    ) x
    WHERE x.rn = 1
),
lagged AS (
    SELECT
        d.*,
        LAG(d.content_hash) OVER (
            PARTITION BY d.listing_key
            ORDER BY d.ingest_date, d.ingested_at, d.run_id
        ) AS prev_content_hash,
        LAG(d.price) OVER (
            PARTITION BY d.listing_key
            ORDER BY d.ingest_date, d.ingested_at, d.run_id
        ) AS prev_price,
        LAG(d.starting_price) OVER (
            PARTITION BY d.listing_key
            ORDER BY d.ingest_date, d.ingested_at, d.run_id
        ) AS prev_starting_price,
        LAG(d.availability_status) OVER (
            PARTITION BY d.listing_key
            ORDER BY d.ingest_date, d.ingested_at, d.run_id
        ) AS prev_availability_status,
        LAG(d.run_id) OVER (
            PARTITION BY d.listing_key
            ORDER BY d.ingest_date, d.ingested_at, d.run_id
        ) AS prev_run_id
    FROM daily d
)
SELECT
    CONVERT(VARCHAR(64), HASHBYTES(
        'SHA2_256',
        CONCAT(
            COALESCE(listing_key, ''), '|',
            COALESCE(CONVERT(VARCHAR(10), ingest_date, 120), ''), '|',
            COALESCE(run_id, '')
        )
    ), 2) AS change_event_id,
    listing_key,
    source_group,
    source_name,
    builder_name,
    community_name,
    record_type,
    ingest_date,
    ingested_at AS detected_at,
    prev_run_id,
    run_id,
    CASE
        WHEN prev_content_hash IS NULL THEN 'added'
        WHEN COALESCE(prev_price, -1) <> COALESCE(price, -1)
          OR COALESCE(prev_starting_price, -1) <> COALESCE(starting_price, -1)
            THEN 'price_changed'
        WHEN COALESCE(prev_availability_status, '') <> COALESCE(availability_status, '')
            THEN 'status_changed'
        WHEN prev_content_hash <> content_hash
            THEN 'attribute_changed'
        ELSE NULL
    END AS change_type,
    CONCAT(
        '{\"price\":', COALESCE(CONVERT(VARCHAR(32), prev_price), 'null'),
        ',\"starting_price\":', COALESCE(CONVERT(VARCHAR(32), prev_starting_price), 'null'),
        ',\"availability_status\":\"', REPLACE(COALESCE(prev_availability_status, ''), '\"', ''), '\"}'
    ) AS before_json,
    CONCAT(
        '{\"price\":', COALESCE(CONVERT(VARCHAR(32), price), 'null'),
        ',\"starting_price\":', COALESCE(CONVERT(VARCHAR(32), starting_price), 'null'),
        ',\"availability_status\":\"', REPLACE(COALESCE(availability_status, ''), '\"', ''), '\"}'
    ) AS after_json
FROM lagged
WHERE prev_content_hash IS NULL
   OR prev_content_hash <> content_hash
