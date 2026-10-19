{{ config(materialized='view', schema='analytics', alias='pipeline_health_obt') }}

/*
  Pipeline health one-big-table for utilities monitoring.
  Grain: one row per orchestrator / pipeline audit / parity check event.
  No schedule — consume via report or ad-hoc query.
*/

WITH orch AS (
    SELECT
        CAST(orchestrator_audit_id AS VARCHAR(64)) AS event_id,
        'orchestrator' AS event_source,
        pipeline_name,
        pipeline_run_id AS run_id,
        run_status AS status,
        start_time,
        end_time,
        failed_activity_name AS detail,
        CAST(NULL AS VARCHAR(20)) AS layer,
        CAST(NULL AS BIGINT) AS row_delta
    FROM {{ source('control', 'audit_orchestrator_control') }}
),
pipe AS (
    SELECT
        CAST(pipeline_audit_id AS VARCHAR(64)) AS event_id,
        'pipeline' AS event_source,
        pipeline_name,
        CAST(NULL AS VARCHAR(64)) AS run_id,
        run_status AS status,
        start_time,
        end_time,
        CAST(NULL AS VARCHAR(500)) AS detail,
        CAST(NULL AS VARCHAR(20)) AS layer,
        CAST(NULL AS BIGINT) AS row_delta
    FROM {{ source('control', 'audit_pipeline_control') }}
),
parity AS (
    SELECT
        CAST(run_id AS VARCHAR(64)) + '-' + CAST(check_seq AS VARCHAR(20)) AS event_id,
        'parity' AS event_source,
        fd_object AS pipeline_name,
        run_id,
        status,
        checked_at AS start_time,
        checked_at AS end_time,
        notes AS detail,
        layer,
        row_delta
    FROM {{ source('control', 'parity_check') }}
)
SELECT * FROM orch
UNION ALL
SELECT * FROM pipe
UNION ALL
SELECT * FROM parity
