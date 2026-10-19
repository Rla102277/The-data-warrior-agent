{{ config(materialized='view', schema='analytics', alias='fiscal_period_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row period lives on analytics.fiscal_period.

SELECT * FROM {{ ref('fiscal_period') }}
