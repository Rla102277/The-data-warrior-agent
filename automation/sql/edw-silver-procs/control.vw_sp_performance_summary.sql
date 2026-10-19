-- View to get SP performance summary with net record counts
CREATE   VIEW [control].[vw_sp_performance_summary] AS
WITH sp_stats AS (
    SELECT
        procedure_name,
        COUNT(*) as total_runs,
        COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) as success_runs,
        COUNT(CASE WHEN status = 'FAILURE' THEN 1 END) as failure_runs,
        MAX(start_time) as latest_run_date,
        AVG(CAST(duration_seconds AS FLOAT)) as avg_duration_seconds,
        -- Format average runtime as hours, minutes, seconds
        CASE
            WHEN CAST(AVG(CAST(duration_seconds AS FLOAT)) AS INT) / 3600 > 0 THEN
                CAST(CAST(AVG(CAST(duration_seconds AS FLOAT)) AS INT) / 3600 AS VARCHAR) + 'h '
            ELSE ''
        END +
        CASE
            WHEN (CAST(AVG(CAST(duration_seconds AS FLOAT)) AS INT) % 3600) / 60 > 0 THEN
                CAST((CAST(AVG(CAST(duration_seconds AS FLOAT)) AS INT) % 3600) / 60 AS VARCHAR) + 'm '
            ELSE ''
        END +
        CASE
            WHEN CAST(AVG(CAST(duration_seconds AS FLOAT)) AS INT) % 60 > 0 THEN
                CAST(CAST(AVG(CAST(duration_seconds AS FLOAT)) AS INT) % 60 AS VARCHAR) + 's'
            ELSE '0s'
        END AS avg_runtime,
        -- Calculate time since last run
        CASE
            WHEN DATEDIFF(SECOND, MAX(start_time), GETDATE()) / 86400 > 0 THEN
                CAST(DATEDIFF(SECOND, MAX(start_time), GETDATE()) / 86400 AS VARCHAR) + 'd '
            ELSE ''
        END +
        CASE
            WHEN (DATEDIFF(SECOND, MAX(start_time), GETDATE()) % 86400) / 3600 > 0 THEN
                CAST((DATEDIFF(SECOND, MAX(start_time), GETDATE()) % 86400) / 3600 AS VARCHAR) + 'h '
            ELSE ''
        END +
        CASE
            WHEN (DATEDIFF(SECOND, MAX(start_time), GETDATE()) % 3600) / 60 > 0 THEN
                CAST((DATEDIFF(SECOND, MAX(start_time), GETDATE()) % 3600) / 60 AS VARCHAR) + 'm '
            ELSE ''
        END +
        CASE
            WHEN DATEDIFF(SECOND, MAX(start_time), GETDATE()) % 60 > 0 THEN
                CAST(DATEDIFF(SECOND, MAX(start_time), GETDATE()) % 60 AS VARCHAR) + 's'
            ELSE '0s'
        END AS time_since_last_run,
        -- Calculate freshness status
        CASE
            WHEN MAX(start_time) >= DATEADD(HOUR, -24, GETDATE())
                 AND (
                     SUM(COALESCE(records_inserted, 0)) +
                     SUM(COALESCE(records_updated, 0)) +
                     SUM(COALESCE(records_deleted, 0))
                 ) > 0
            THEN 'FRESH'
            WHEN MAX(start_time) >= DATEADD(HOUR, -24, GETDATE())
                 AND (
                     SUM(COALESCE(records_inserted, 0)) +
                     SUM(COALESCE(records_updated, 0)) +
                     SUM(COALESCE(records_deleted, 0))
                 ) = 0
            THEN 'NO RECORDS'
            WHEN MAX(start_time) >= DATEADD(HOUR, -48, GETDATE())
            THEN 'AGING'
            ELSE 'STALE'
        END AS freshness_status
    FROM [EDW_Silver].[control].[audit_sp_control]
    WHERE procedure_name IS NOT NULL
    GROUP BY procedure_name
),
sp_table_mapping AS (
    -- Extract table names from procedure names
    SELECT
        procedure_name,
        CASE
            -- Handle sp_load_tablename pattern
            WHEN procedure_name LIKE 'sp_load_%' THEN SUBSTRING(procedure_name, 9, LEN(procedure_name))
            -- Handle sp_tablename_load pattern
            WHEN procedure_name LIKE 'sp_%_load' THEN SUBSTRING(procedure_name, 4, LEN(procedure_name) - 8)
            -- Handle other patterns with _load_ in the middle
            WHEN procedure_name LIKE '%_load_%' THEN
                SUBSTRING(procedure_name,
                    CHARINDEX('_load_', procedure_name) + 6,
                    LEN(procedure_name) - CHARINDEX('_load_', procedure_name) - 5)
            -- Default case - remove sp_ prefix if it exists
            WHEN procedure_name LIKE 'sp_%' THEN SUBSTRING(procedure_name, 4, LEN(procedure_name))
            ELSE procedure_name
        END as table_name
    FROM (SELECT DISTINCT procedure_name FROM [EDW_Silver].[control].[audit_sp_control]) sp_list
)
SELECT
    stm.table_name,
    stm.procedure_name as pipeline_name,
    sps.latest_run_date,
    sps.total_runs,
    sps.success_runs,
    sps.failure_runs,
    ROUND(sps.avg_duration_seconds, 2) as avg_runtime_seconds,
    sps.avg_runtime,
    CASE
        WHEN sps.avg_duration_seconds IS NULL THEN 'Unknown'
        WHEN sps.avg_duration_seconds <= 300 THEN 'Normal'
        WHEN sps.avg_duration_seconds <= 1800 THEN 'Moderate'
        ELSE 'Long Running'
    END as pipeline_performance,
    sps.freshness_status as pipeline_freshness,
    CASE
        WHEN sps.total_runs > 0
        THEN ROUND((CAST(sps.success_runs AS FLOAT) / sps.total_runs) * 100, 2)
        ELSE 0
    END as success_rate_percentage,
    sps.time_since_last_run,
    COALESCE(
        (SELECT TOP 1 total_record_count
         FROM [EDW_Silver].[control].[audit_sp_control] asc2
         WHERE asc2.procedure_name = stm.procedure_name
           AND asc2.status = 'SUCCESS'
           AND asc2.total_record_count IS NOT NULL
         ORDER BY asc2.start_time DESC
        ), 0
    ) as current_record_count,
    CONVERT(VARCHAR(19), GETDATE(), 120) AS time_of_read
FROM sp_stats sps
INNER JOIN sp_table_mapping stm ON sps.procedure_name = stm.procedure_name;