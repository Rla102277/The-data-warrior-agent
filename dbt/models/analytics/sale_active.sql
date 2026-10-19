{{ config(materialized='view', schema='analytics', alias='sale_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row sale lives on analytics.sale.

SELECT * FROM {{ ref('sale') }}
