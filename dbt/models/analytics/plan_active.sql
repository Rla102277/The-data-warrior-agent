{{ config(materialized='view', schema='analytics', alias='plan_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Plan lives on analytics.plan.

SELECT * FROM {{ ref('plan') }}
