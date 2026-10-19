{{ config(materialized='view', schema='analytics', alias='job_task_active', tags=['unpublished','wrapper']) }}

-- Unpublished compatibility wrapper. Current-row job_task lives on analytics.job_task.

SELECT * FROM {{ ref('job_task') }}
