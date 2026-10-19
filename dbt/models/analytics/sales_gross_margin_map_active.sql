{{ config(materialized='view', schema='analytics', alias='sales_gross_margin_map_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Map lives on analytics.sales_gross_margin_map.

SELECT * FROM {{ ref('sales_gross_margin_map') }}
