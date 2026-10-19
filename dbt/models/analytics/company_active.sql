{{ config(materialized='view', schema='analytics', alias='company_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row company lives on analytics.company.

SELECT * FROM {{ ref('company') }}
