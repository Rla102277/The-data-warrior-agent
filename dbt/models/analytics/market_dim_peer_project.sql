{{ config(materialized='view', schema='analytics', alias='market_dim_peer_project') }}

/*
  Selectable GBP peer-project dim for Peer Arena.
  Rows come from stamped peer project links.
*/

SELECT
    MIN(project_code) AS project_code,
    MIN(project_name) AS project_name,
    MIN(operating_unit_code) AS operating_unit_code
FROM {{ ref('market_peer_project_obt') }}
WHERE is_active = 1
  AND NULLIF(LTRIM(RTRIM(COALESCE(project_code, ''))), '') IS NOT NULL
GROUP BY LOWER(LTRIM(RTRIM(project_code)))
