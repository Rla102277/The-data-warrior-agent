{{ config(materialized='view', schema='analytics', alias='operating_unit_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row OU lives on analytics.operating_unit.

SELECT * FROM {{ ref('operating_unit') }}
