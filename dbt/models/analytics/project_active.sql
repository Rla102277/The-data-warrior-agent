{{ config(materialized='view', schema='analytics', alias='project_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row project lives on analytics.project.

SELECT * FROM {{ ref('project') }}
