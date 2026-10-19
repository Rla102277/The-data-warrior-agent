{{ config(materialized='view', schema='analytics', alias='web_community') }}

-- Website community rows, Zonda community analog (D13).
-- Grain: one builder presence at a community (source_group + source_name).
-- Not ERP community. Not dbo.

SELECT
    CONVERT(VARCHAR(64), HASHBYTES(
        'SHA2_256',
        CONCAT(
            COALESCE(source_group, ''), '|',
            COALESCE(source_name, ''), '|',
            COALESCE(community_name, '')
        )
    ), 2) AS community_key,
    community_name AS name,
    MAX(builder_name) AS builder_name,
    MAX(city) AS city,
    MAX(state) AS state_prov,
    MAX(country) AS country,
    CAST(NULL AS VARCHAR(16)) AS zip_code,
    CAST(NULL AS VARCHAR(64)) AS county,
    CAST(NULL AS VARCHAR(256)) AS address,
    CAST(NULL AS VARCHAR(MAX)) AS description,
    MAX(listing_url) AS website,
    CAST(NULL AS VARCHAR(512)) AS custom_website,
    CAST(NULL AS VARCHAR(256)) AS website_title,
    CAST(NULL AS VARCHAR(64)) AS phone,
    CAST(NULL AS VARCHAR(64)) AS community_phone_2,
    CAST(NULL AS VARCHAR(64)) AS community_phone_3,
    CAST(NULL AS VARCHAR(256)) AS contact_email,
    CAST(NULL AS VARCHAR(256)) AS office_hours,
    CAST(NULL AS VARCHAR(128)) AS division_name,
    CAST(CASE
        WHEN MAX(CASE
            WHEN LOWER(COALESCE(availability_group, '')) = 'available' THEN 1
            ELSE 0
        END) = 1 THEN 1
        ELSE 0
    END AS BIT) AS online,
    MAX(listing_key) AS integration_id,
    MAX(ingested_at) AS loaded_at,
    source_group,
    source_name
FROM {{ ref('web_listing_obt') }}
GROUP BY
    source_group,
    source_name,
    community_name
