{{ config(materialized='view', schema='analytics', alias='web_plan') }}

-- Website floor plans, Zonda plans analog (D13 singular plan).
-- Grain: listing_key on record_type = plan.
-- Not ERP analytics.plan. Not dbo.

SELECT
    listing_key AS plan_key,
    CONVERT(VARCHAR(64), HASHBYTES(
        'SHA2_256',
        CONCAT(
            COALESCE(source_group, ''), '|',
            COALESCE(source_name, ''), '|',
            COALESCE(community_name, '')
        )
    ), 2) AS community_key,
    plan_name AS name,
    plan_number AS model_number,
    builder_name,
    CAST(bedrooms AS VARCHAR(16)) AS bedrooms,
    CAST(bathrooms AS VARCHAR(16)) AS bathrooms,
    square_feet AS square_footage,
    CAST(stories AS FLOAT) AS floors,
    CAST(garage_spaces AS VARCHAR(16)) AS garage,
    CAST(NULL AS BIT) AS basement_included,
    CAST(NULL AS VARCHAR(128)) AS extra_rooms,
    CAST(NULL AS VARCHAR(32)) AS hide_room_dimensions,
    CAST(NULL AS VARCHAR(64)) AS plan_group,
    CAST(NULL AS VARCHAR(MAX)) AS description,
    CAST(starting_price AS FLOAT) AS price,
    COALESCE(plan_url, listing_url) AS website,
    CAST(CASE
        WHEN LOWER(COALESCE(availability_group, '')) = 'sold' THEN 0
        ELSE 1
    END AS BIT) AS online,
    listing_key AS integration_id,
    ingested_at AS loaded_at,
    source_group,
    source_name,
    community_name,
    elevation
FROM {{ ref('web_listing_obt') }}
WHERE LOWER(COALESCE(record_type, '')) = 'plan'
