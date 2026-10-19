{{ config(materialized='view', schema='analytics', alias='division_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row division lives on analytics.division.

SELECT * FROM {{ ref('division') }}
