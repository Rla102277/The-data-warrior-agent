{{ config(materialized='view', schema='analytics', alias='sales_gross_margin_assumptions_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Line grain lives on analytics.sales_gross_margin_assumptions_det.

SELECT * FROM {{ ref('sales_gross_margin_assumptions_det') }}
