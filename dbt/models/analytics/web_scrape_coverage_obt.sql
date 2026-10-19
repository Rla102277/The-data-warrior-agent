{{ config(materialized='view', schema='analytics', alias='web_scrape_coverage_obt') }}

-- Current scrape coverage / freshness / completeness per active source.
-- Completeness mirrors notebook listing_complete / records_complete (60% threshold).

WITH latest_heartbeat AS (
    SELECT *
    FROM (
        SELECT
            h.*,
            ROW_NUMBER() OVER (
                PARTITION BY h.source_group, h.source_name
                ORDER BY h.checked_at DESC, h.heartbeat_id DESC
            ) AS rn
        FROM {{ source('control', 'web_scrape_heartbeat_det') }} h
    ) x
    WHERE x.rn = 1
),
latest_defer AS (
    SELECT *
    FROM (
        SELECT
            d.*,
            ROW_NUMBER() OVER (
                PARTITION BY d.source_group, d.source_name
                ORDER BY d.logged_at DESC, d.defer_id DESC
            ) AS rn
        FROM {{ source('control', 'web_scrape_defer_det') }} d
    ) x
    WHERE x.rn = 1
),
latest_queue AS (
    SELECT *
    FROM (
        SELECT
            q.*,
            ROW_NUMBER() OVER (
                PARTITION BY q.source_group, q.source_name
                ORDER BY q.queued_at DESC, q.queue_id DESC
            ) AS rn
        FROM {{ source('control', 'web_scrape_queue') }} q
    ) x
    WHERE x.rn = 1
),
current_enriched AS (
    SELECT
        c.source_group,
        c.source_name,
        c.record_type,
        c.last_seen_at,
        c.last_change_at,
        CASE
            WHEN LOWER(COALESCE(c.record_type, '')) = 'collection'
                 AND LOWER(COALESCE(c.availability_status, '')) LIKE '%sold%'
                THEN 1
            WHEN LOWER(COALESCE(c.record_type, '')) = 'plan'
                 AND NULLIF(LTRIM(RTRIM(COALESCE(c.plan_name, ''))), '') IS NOT NULL
                 AND (
                        c.starting_price IS NOT NULL
                     OR c.square_feet IS NOT NULL
                 )
                THEN 1
            WHEN LOWER(COALESCE(c.record_type, '')) <> 'plan'
                 AND LOWER(COALESCE(c.record_type, '')) <> 'collection'
                 AND (
                        NULLIF(LTRIM(RTRIM(COALESCE(c.address, ''))), '') IS NOT NULL
                     OR NULLIF(LTRIM(RTRIM(COALESCE(c.plan_name, ''))), '') IS NOT NULL
                 )
                 AND (c.price IS NOT NULL OR c.starting_price IS NOT NULL)
                 AND (c.square_feet IS NOT NULL OR c.bedrooms IS NOT NULL)
                THEN 1
            ELSE 0
        END AS is_complete_row,
        CASE
            WHEN NULLIF(LTRIM(RTRIM(COALESCE(c.address, ''))), '') IS NOT NULL
              OR NULLIF(LTRIM(RTRIM(COALESCE(c.plan_name, ''))), '') IS NOT NULL
                THEN 1 ELSE 0
        END AS has_identity,
        CASE
            WHEN c.price IS NOT NULL OR c.starting_price IS NOT NULL THEN 1 ELSE 0
        END AS has_price,
        CASE
            WHEN c.square_feet IS NOT NULL OR c.bedrooms IS NOT NULL THEN 1 ELSE 0
        END AS has_size
    FROM {{ ref('web_listing_current') }} c
    WHERE c.is_active = 1
),
current_rows AS (
    SELECT
        source_group,
        source_name,
        COUNT(*) AS current_listing_count,
        SUM(CASE WHEN LOWER(COALESCE(record_type, '')) = 'inventory' THEN 1 ELSE 0 END) AS inventory_count,
        SUM(CASE WHEN LOWER(COALESCE(record_type, '')) = 'plan' THEN 1 ELSE 0 END) AS plan_count,
        SUM(is_complete_row) AS complete_row_count,
        CAST(
            CASE
                WHEN COUNT(*) = 0 THEN NULL
                ELSE 100.0 * SUM(is_complete_row) / COUNT(*)
            END AS DECIMAL(5, 1)
        ) AS completeness_pct,
        CAST(
            CASE
                WHEN COUNT(*) = 0 THEN NULL
                ELSE 100.0 * SUM(has_identity) / COUNT(*)
            END AS DECIMAL(5, 1)
        ) AS identity_fill_pct,
        CAST(
            CASE
                WHEN COUNT(*) = 0 THEN NULL
                ELSE 100.0 * SUM(has_price) / COUNT(*)
            END AS DECIMAL(5, 1)
        ) AS price_fill_pct,
        CAST(
            CASE
                WHEN COUNT(*) = 0 THEN NULL
                ELSE 100.0 * SUM(has_size) / COUNT(*)
            END AS DECIMAL(5, 1)
        ) AS size_fill_pct,
        MAX(last_seen_at) AS last_seen_at,
        MAX(last_change_at) AS last_change_at
    FROM current_enriched
    GROUP BY source_group, source_name
)
SELECT
    s.source_group,
    s.source_name,
    s.community_name,
    s.builder_name,
    s.scrape_tier,
    s.strategic_rank,
    CAST(CASE WHEN COALESCE(s.strategic_rank, 5) = 1 THEN 1 ELSE 0 END AS BIT) AS is_strategic,
    s.heartbeat_ttl_hours,
    s.is_active,
    s.listing_url,
    h.checked_at AS heartbeat_checked_at,
    h.status_code AS heartbeat_status,
    h.queue_reason,
    q.queue_status,
    q.queued_at AS queue_queued_at,
    q.run_tier AS queue_run_tier,
    COALESCE(c.current_listing_count, 0) AS current_listing_count,
    COALESCE(c.inventory_count, 0) AS inventory_count,
    COALESCE(c.plan_count, 0) AS plan_count,
    COALESCE(c.complete_row_count, 0) AS complete_row_count,
    c.completeness_pct,
    c.identity_fill_pct,
    c.price_fill_pct,
    c.size_fill_pct,
    c.last_seen_at,
    c.last_change_at,
    s.last_deferred_at AS last_deferred_at,
    -- Current open defer only (source.defer_reason). Historical rows stay in defer_det.
    NULLIF(LTRIM(RTRIM(s.defer_reason)), '') AS last_defer_reason,
    -- Active defer is source.defer_reason only. Historical defer_det must not
    -- keep recovered sources (e.g. Perry after local Playwright) as deferred.
    -- Fresh complete inventory beats a stale heartbeat (e.g. Jome same-day land).
    CASE
        WHEN NULLIF(LTRIM(RTRIM(COALESCE(s.defer_reason, ''))), '') IS NOT NULL
            THEN 'deferred'
        WHEN COALESCE(c.current_listing_count, 0) = 0 THEN 'empty'
        WHEN COALESCE(c.completeness_pct, 0) < 60 THEN 'incomplete'
        WHEN COALESCE(c.completeness_pct, 0) >= 60
             AND c.last_seen_at IS NOT NULL
             AND c.last_seen_at >= DATEADD(
                    hour,
                    -COALESCE(NULLIF(s.heartbeat_ttl_hours, 0), 48),
                    SYSUTCDATETIME()
                 )
            THEN 'healthy'
        WHEN h.status_code IN ('stale_missing', 'stale_ttl') THEN 'stale'
        WHEN h.status_code = 'changed' THEN 'changed'
        ELSE 'healthy'
    END AS coverage_status
FROM {{ source('control', 'web_scrape_source') }} s
LEFT JOIN latest_heartbeat h
    ON h.source_group = s.source_group
   AND h.source_name = s.source_name
LEFT JOIN latest_defer d
    ON d.source_group = s.source_group
   AND d.source_name = s.source_name
LEFT JOIN latest_queue q
    ON q.source_group = s.source_group
   AND q.source_name = s.source_name
LEFT JOIN current_rows c
    ON c.source_group = s.source_group
   AND c.source_name = s.source_name
WHERE s.is_active = 1
