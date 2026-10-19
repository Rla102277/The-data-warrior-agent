{{ config(materialized='view', schema='analytics', alias='lot_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row lot lives on analytics.lot.

SELECT * FROM {{ ref('lot') }}
