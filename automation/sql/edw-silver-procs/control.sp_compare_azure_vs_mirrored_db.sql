/*
*******************************************************************************************************************************************************************************************************
    OBJECT NAME    : sp_compare_azure_vs_mirrored_db
    CREATED BY     : Kamalesh Radhakrishnan
    CREATED ON     : 19/06/2025
    PURPOSE        : Stored procedure to audit mirrored data.
    INPUT PARAMS   : CreatedDate
    OUT PARAMS     : BOOLEAN
    EXEC Statement : EXEC control.sp_compare_azure_vs_mirrored_db(<CreatedDate>);
*******************************************************************************************************************************************************************************************************
*/
CREATE PROCEDURE control.sp_compare_azure_vs_mirrored_db
    @CreatedDate VARCHAR(20)
AS
BEGIN
    -- Step 1: Source and Target column sets
    WITH ColumnPairs AS (
        SELECT
            server,
            table_catalog,
            table_schema,
            table_name,
            column_name
        FROM EDW_Silver.control.column_validation
    ),

    -- All tables across both servers
    AllTables AS (
        SELECT DISTINCT
            table_catalog,
            table_schema,
            table_name
        FROM ColumnPairs
    ),

    -- Azure SQL Server columns
    SourceCols AS (
        SELECT *
        FROM ColumnPairs
        WHERE server = 'Azure SQL Server'
    ),

    -- Mirrored DB columns
    TargetCols AS (
        SELECT *
        FROM ColumnPairs
        WHERE server = 'Mirrored DB' --fab
    ),

    -- Step 2: Differences — columns that exist in one server but not the other
    ColumnDiffs AS (
        SELECT
            sc.table_catalog,
            sc.table_schema,
            sc.table_name,
            sc.column_name
        FROM SourceCols sc
        LEFT JOIN TargetCols tc
            ON sc.table_catalog = tc.table_catalog
            AND sc.table_schema = tc.table_schema
            AND sc.table_name = tc.table_name
            AND sc.column_name = tc.column_name
        WHERE tc.column_name IS NULL

        UNION

        SELECT
            tc.table_catalog,
            tc.table_schema,
            tc.table_name,
            tc.column_name
        FROM TargetCols tc
        LEFT JOIN SourceCols sc
            ON tc.table_catalog = sc.table_catalog
            AND tc.table_schema = sc.table_schema
            AND tc.table_name = sc.table_name
            AND tc.column_name = sc.column_name
        WHERE sc.column_name IS NULL
    ),

    -- Step 3: Aggregate column differences
    DiffAgg AS (
        SELECT
            table_catalog,
            table_schema,
            table_name,
            STRING_AGG(column_name, ', ') AS differing_columns,
            COUNT(*) AS column_diff_count
        FROM ColumnDiffs
        GROUP BY table_catalog, table_schema, table_name
    ),

    -- Step 4: Row count in source and target
    SourceCounts AS (
        SELECT
            table_catalog,
            table_schema,
            table_name,
            COUNT(*) AS source_column_count
        FROM SourceCols
        GROUP BY table_catalog, table_schema, table_name
    ),

    TargetCounts AS (
        SELECT
            table_catalog,
            table_schema,
            table_name,
            COUNT(*) AS target_column_count
        FROM TargetCols
        GROUP BY table_catalog, table_schema, table_name
    ),

    -- Step 5: Final output
    RecordCounts AS (
        SELECT
            table_name,
            MAX(CASE WHEN server = 'Azure SQL Server' THEN record_count END) AS source_record_count,
            MAX(CASE WHEN server = 'Mirrored DB' THEN record_count END) AS target_record_count
        FROM EDW_Silver.control.row_validation
        GROUP BY table_name
    )
    INSERT INTO EDW_Silver.control.azure_vs_mirrored_db_audit_log (created_date,table_name,source_record_count,target_record_count,row_count_difference,row_validation_status,source_column_count,target_column_count,column_count_difference,differing_columns,column_validation_status)
    SELECT
        CAST(@CreatedDate AS DATETIME2(0)) as created_date,
        at.table_catalog + '.' + at.table_schema + '.' + at.table_name AS table_name,
        rc.source_record_count,
        rc.target_record_count,
        ABS(rc.source_record_count - rc.target_record_count) AS row_count_difference,
        CASE 
            WHEN rc.source_record_count = rc.target_record_count THEN 'Match' 
            ELSE 'Mismatch' 
        END AS row_validation_status,
        sc.source_column_count AS source_column_count,
        tc.target_column_count AS target_column_count,
        ISNULL(da.column_diff_count, 0) AS column_count_difference,
        ISNULL(da.differing_columns, '') AS differing_columns,
        CASE 
            WHEN ISNULL(da.column_diff_count, 0) = 0 THEN 'Match' 
            ELSE 'Mismatch' 
        END AS column_validation_status
    FROM AllTables at
    LEFT JOIN RecordCounts rc
        ON rc.table_name = CONCAT(at.table_catalog, '.', at.table_schema, '.', at.table_name)
    LEFT JOIN DiffAgg da
        ON da.table_catalog = at.table_catalog
        AND da.table_schema = at.table_schema
        AND da.table_name = at.table_name
    LEFT JOIN SourceCounts sc
        ON sc.table_catalog = at.table_catalog
        AND sc.table_schema = at.table_schema
        AND sc.table_name = at.table_name
    LEFT JOIN TargetCounts tc
        ON tc.table_catalog = at.table_catalog
        AND tc.table_schema = at.table_schema
        AND tc.table_name = at.table_name
    ORDER BY at.table_catalog + '.' + at.table_schema + '.' + at.table_name;
END;