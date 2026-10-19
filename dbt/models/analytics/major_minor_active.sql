{{ config(materialized='view', schema='analytics', alias='major_minor_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row major_minor lives on analytics.major_minor.

SELECT * FROM {{ ref('major_minor') }}
