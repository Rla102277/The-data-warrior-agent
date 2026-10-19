{{ config(materialized='view', schema='analytics', alias='web_lot') }}

-- Website inventory homes, Zonda lots analog (D13 singular lot).
-- Grain: listing_key on record_type = inventory.
-- Not ERP analytics.lot. Not dbo.

SELECT
    listing_key AS lot_key,
    CONVERT(VARCHAR(64), HASHBYTES(
        'SHA2_256',
        CONCAT(
            COALESCE(source_group, ''), '|',
            COALESCE(source_name, ''), '|',
            COALESCE(community_name, '')
        )
    ), 2) AS community_key,
    address,
    builder_name,
    plan_name AS available_plans,
    CAST(NULL AS VARCHAR(MAX)) AS description,
    CAST(NULL AS VARCHAR(32)) AS garage_orientation,
    CAST(NULL AS VARCHAR(64)) AS lot_group,
    address AS lot_label,
    CAST(NULL AS VARCHAR(32)) AS lot_number,
    CAST(NULL AS VARCHAR(64)) AS lot_option,
    CAST(NULL AS VARCHAR(32)) AS lot_premium_price,
    CAST(lot_size AS VARCHAR(32)) AS lot_sq_ft,
    availability_status AS lot_status,
    CAST(COALESCE(price, display_price) AS VARCHAR(32)) AS price,
    CAST(lot_size AS VARCHAR(32)) AS size,
    CAST(square_feet AS VARCHAR(32)) AS sqft,
    listing_key AS integration_id,
    ingested_at AS loaded_at,
    listing_url AS website,
    source_group,
    source_name,
    community_name,
    city,
    plan_number,
    bedrooms,
    bathrooms,
    estimated_move_in_date
FROM {{ ref('web_listing_obt') }}
WHERE LOWER(COALESCE(record_type, '')) = 'inventory'
