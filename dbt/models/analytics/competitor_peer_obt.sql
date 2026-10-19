{{ config(materialized='view', schema='analytics', alias='competitor_peer_obt') }}

-- Named peer-set rows for Market Intelligence head-to-head.
-- Expands control.web_competitor_peer to focal + peer builder rows.

SELECT
    peer_set_name,
    focal_builder,
    peer_builder,
    focal_builder AS builder_name,
    CAST('focal' AS VARCHAR(16)) AS peer_role,
    is_active,
    notes
FROM {{ source('control', 'web_competitor_peer') }}
WHERE is_active = 1

UNION ALL

SELECT
    peer_set_name,
    focal_builder,
    peer_builder,
    peer_builder AS builder_name,
    CAST('peer' AS VARCHAR(16)) AS peer_role,
    is_active,
    notes
FROM {{ source('control', 'web_competitor_peer') }}
WHERE is_active = 1
