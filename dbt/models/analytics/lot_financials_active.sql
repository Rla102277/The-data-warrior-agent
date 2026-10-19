{{ config(materialized='view', schema='analytics', alias='lot_financials_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Line grain lives on analytics.lot_financials_det.

SELECT * FROM {{ ref('lot_financials_det') }}
