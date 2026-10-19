CREATE VIEW [control].[vw_pipeline_performance_summary] AS
WITH pipeline_stats AS (
    SELECT 
        pipeline_name,
        COUNT(*) as total_runs,
        COUNT(CASE WHEN run_status = 'SUCCESS' THEN 1 END) as success_runs,
        COUNT(CASE WHEN run_status = 'FAILURE' THEN 1 END) as failure_runs,
        MAX(start_time) as latest_run_date,
        AVG(
            CAST(DATEDIFF(SECOND, start_time, end_time) AS INT)
        ) as avg_duration_seconds,
        CASE 
            WHEN AVG(CAST(DATEDIFF(SECOND, start_time, end_time) AS INT)) / 3600 > 0 THEN 
                CAST(AVG(CAST(DATEDIFF(SECOND, start_time, end_time) AS INT)) / 3600 AS VARCHAR) + 'h '
            ELSE ''
        END +
        CASE 
            WHEN (AVG(CAST(DATEDIFF(SECOND, start_time, end_time) AS INT)) % 3600) / 60 > 0 THEN 
                CAST((AVG(CAST(DATEDIFF(SECOND, start_time, end_time) AS INT)) % 3600) / 60 AS VARCHAR) + 'm '
            ELSE ''
        END +
        CASE 
            WHEN AVG(CAST(DATEDIFF(SECOND, start_time, end_time) AS INT)) % 60 > 0 THEN 
                CAST(AVG(CAST(DATEDIFF(SECOND, start_time, end_time) AS INT)) % 60 AS VARCHAR) + 's'
            ELSE ''
        END AS avg_runtime,
        -- Calculate days since last run for freshness
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
            ELSE ''
        END AS time_since_last_run
    FROM [EDW_Silver].[control].[audit_pipeline_control]
    WHERE pipeline_name IS NOT NULL
    GROUP BY pipeline_name
),
sp_table_mapping AS (
    -- Extract table names from procedure names (assuming naming convention like sp_load_tablename or similar)
    SELECT
        procedure_name,
        CASE 
            WHEN procedure_name LIKE 'sp_load_%' THEN SUBSTRING(procedure_name, 9, LEN(procedure_name))
            WHEN procedure_name LIKE 'sp_%_load' THEN SUBSTRING(procedure_name, 4, LEN(procedure_name) - 8)
            WHEN procedure_name LIKE '%_load_%' THEN 
                SUBSTRING(procedure_name, 
                    CHARINDEX('_load_', procedure_name) + 6, 
                    LEN(procedure_name) - CHARINDEX('_load_', procedure_name) - 5)
            ELSE 'Unknown_Table'
        END as table_name,
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
                 SUM(COALESCE(records_inserted,0)) +
                 SUM(COALESCE(records_updated, 0)) +
                 SUM(COALESCE(records_deleted, 0))
             ) = 0
        THEN 'NO RECORDS'
        WHEN MAX(start_time) >= DATEADD(HOUR, -48, GETDATE())
        THEN 'AGING'
        ELSE 'STALE'
    END AS freshness_status
    FROM [EDW_Silver].[control].[audit_sp_control]
	GROUP BY procedure_name
),
pipeline_procedure_mapping AS (
    -- Map pipelines to procedures (you may need to adjust this based on your actual relationships)
    SELECT DISTINCT
        apc.pipeline_name,
        asc1.procedure_name,
        stm.table_name,
		stm.freshness_status
    FROM [EDW_Silver].[control].[audit_pipeline_control] apc
    INNER JOIN [EDW_Silver].[control].[audit_sp_control] asc1 
        ON apc.pipeline_audit_id = asc1.pipeline_audit_id
    INNER JOIN sp_table_mapping stm 
        ON asc1.procedure_name = stm.procedure_name
)
SELECT 
    -- Use COALESCE to handle cases where table mapping might not exist
    COALESCE(ppm.table_name, 'Unknown_Table') as table_name,
    ps.pipeline_name,
    ps.latest_run_date,
    ps.total_runs,
    ps.success_runs,
    ps.failure_runs,
    ROUND(ps.avg_duration_seconds, 2) as avg_runtime_seconds,
    ps.avg_runtime,
    CASE 
        WHEN ps.avg_duration_seconds IS NULL THEN 'Unknown'
        WHEN ps.avg_duration_seconds <= 300 THEN 'Normal'        -- 5 minutes or less
        WHEN ps.avg_duration_seconds <= 1800 THEN 'Moderate'     -- 30 minutes or less
        ELSE 'Long Running'
    END as pipeline_performance,
    ppm.freshness_status as pipeline_freshness,
	
    -- Additional useful metrics
    CASE 
        WHEN ps.total_runs > 0 
        THEN ROUND((CAST(ps.success_runs AS FLOAT) / ps.total_runs) * 100, 2) 
        ELSE 0 
    END as success_rate_percentage,
    ps.time_since_last_run,
    CONVERT(VARCHAR(19), GETDATE(), 120) AS time_of_read
FROM pipeline_stats ps
LEFT JOIN pipeline_procedure_mapping ppm 
    ON ps.pipeline_name = ppm.pipeline_name;
-- If you have multiple table mappings per pipeline, you might want to add:
-- GROUP BY ps.pipeline_name, ps.latest_run_date, ps.total_runs, ps.success_runs, 
--          ps.failure_runs, ps.avg_duration_seconds, ps.days_since_last_run, ppm.table_name
--ORDER BY ps.latest_run_date DESC, ps.pipeline_name;