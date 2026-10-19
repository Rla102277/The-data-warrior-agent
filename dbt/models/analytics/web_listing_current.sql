{{ config(materialized='view', schema='analytics', alias='web_listing_current') }}

-- Current web listing state per listing identity.
-- Grain: one row per listing_key with last seen attributes plus first/last/change timestamps.

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
snapshots AS (
    SELECT
        b.*,
        ROW_NUMBER() OVER (
            PARTITION BY b.listing_key, b.ingest_date
            ORDER BY b.ingested_at DESC, b.run_id DESC
        ) AS daily_rn
    FROM base b
),
daily AS (
    SELECT *
    FROM snapshots
    WHERE daily_rn = 1
),
changes AS (
    SELECT
        d.*,
        LAG(d.content_hash) OVER (
            PARTITION BY d.listing_key
            ORDER BY d.ingest_date, d.ingested_at, d.run_id
        ) AS prev_content_hash,
        CASE
            WHEN LAG(d.content_hash) OVER (
                PARTITION BY d.listing_key
                ORDER BY d.ingest_date, d.ingested_at, d.run_id
            ) IS NULL THEN d.ingested_at
            WHEN LAG(d.content_hash) OVER (
                PARTITION BY d.listing_key
                ORDER BY d.ingest_date, d.ingested_at, d.run_id
            ) <> d.content_hash THEN d.ingested_at
            ELSE NULL
        END AS changed_at
    FROM daily d
),
rollup AS (
    SELECT
        c.listing_key,
        MIN(c.ingested_at) AS first_seen_at,
        MAX(c.ingested_at) AS last_seen_at,
        MAX(c.changed_at) AS last_change_at
    FROM changes c
    GROUP BY c.listing_key
),
latest AS (
    SELECT
        c.*,
        ROW_NUMBER() OVER (
            PARTITION BY c.listing_key
            ORDER BY c.ingested_at DESC, c.run_id DESC
        ) AS rn
    FROM changes c
)
SELECT
    l.listing_key,
    l.builder_name,
    l.community_name,
    l.record_type,
    l.plan_name,
    l.elevation,
    l.plan_number,
    l.price,
    l.starting_price,
    l.square_feet,
    l.bedrooms,
    l.bathrooms,
    l.stories,
    l.garage_spaces,
    l.lot_size,
    l.address,
    l.availability_status,
    l.estimated_move_in_date,
    l.listing_url,
    l.plan_url,
    l.run_id AS source_run_id,
    l.ingest_date,
    l.ingested_at,
    l.scraper,
    l.source_name,
    l.source_group,
    l.fill_source,
    l.fill_ingest_date,
    l.content_hash,
    r.first_seen_at,
    r.last_seen_at,
    COALESCE(r.last_change_at, r.first_seen_at) AS last_change_at,
    CAST(CASE
        WHEN l.ingested_at = r.last_seen_at THEN 1
        ELSE 0
    END AS BIT) AS is_active
FROM latest l
INNER JOIN rollup r
    ON r.listing_key = l.listing_key
WHERE l.rn = 1
