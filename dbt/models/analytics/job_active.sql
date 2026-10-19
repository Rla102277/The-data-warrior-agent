{{ config(materialized='view', schema='analytics', alias='job_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row job lives on analytics.job.

SELECT * FROM {{ ref('job') }}
