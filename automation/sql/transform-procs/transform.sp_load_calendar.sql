CREATE   PROCEDURE transform.sp_load_calendar
    @CreatedBy VARCHAR(100) = 'GB_User',
    @JobRunId VARCHAR(100),
    @LoadType VARCHAR(20) = '',
    @AuditId VARCHAR(100) = '',
    @OrchestratorAuditId VARCHAR(100) = ''
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @CurrentDatetime DATETIME2(3) = GETDATE();
        DECLARE @Today DATE = CAST(GETDATE() AS DATE);
        DECLARE @StartYear INT = YEAR(@Today) - 10;
        DECLARE @EndYear INT = YEAR(@Today) + 10;
        DECLARE @StartDate DATE = DATEFROMPARTS(@StartYear, 1, 1);
        DECLARE @EndDate DATE = DATEFROMPARTS(@EndYear, 12, 31);

        -- Truncate existing data (one-time load)
        TRUNCATE TABLE transform.calendar;

        -- Generate date range up to 10 years back and forward (20 years total)
        WITH base AS (
            SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS n
            FROM 
                (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) a(n),
                (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) b(n),
                (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) c(n),
                (VALUES (0),(0),(0),(0),(0),(0),(0),(0),(0),(0)) d(n)
        ),
        DateSequence AS (
            SELECT DATEADD(DAY, n, @StartDate) AS DateValue
            FROM base
            WHERE DATEADD(DAY, n, @StartDate) <= @EndDate
        )
        INSERT INTO transform.calendar (
            date_id,
            full_date,
            day_of_week,
            day_name,
            day_of_month,
            day_of_year,
            week_start_date,
            week_end_date,
            week_of_year,
            iso_week_of_year,
            month,
            month_name,
            year,
            quarter,
            fiscal_year,
            fiscal_quarter,
            is_weekend,
            is_holiday,
            holiday_name,
            created_date,
            created_by,
            created_job_run_id
        )
        SELECT 
            CAST(FORMAT(ds.DateValue, 'yyyyMMdd') AS INT),
            ds.DateValue,
            DATEPART(WEEKDAY, ds.DateValue),
            DATENAME(WEEKDAY, ds.DateValue),
            DAY(ds.DateValue),
            DATEPART(DAYOFYEAR, ds.DateValue),

            -- Week start as TUESDAY
            DATEADD(DAY, (9 - DATEPART(WEEKDAY, ds.DateValue)) % 7, ds.DateValue),
            -- Week end as MONDAY
            DATEADD(DAY, (8 - DATEPART(WEEKDAY, ds.DateValue)) % 7, ds.DateValue),

            DATEPART(WEEK, ds.DateValue),
            DATEPART(ISO_WEEK, ds.DateValue),
            MONTH(ds.DateValue),
            DATENAME(MONTH, ds.DateValue),
            YEAR(ds.DateValue),
            DATEPART(QUARTER, ds.DateValue),

            CASE WHEN MONTH(ds.DateValue) >= 4 THEN YEAR(ds.DateValue) + 1 ELSE YEAR(ds.DateValue) END,
            CASE 
                WHEN MONTH(ds.DateValue) BETWEEN 4 AND 6 THEN 'FQ1'
                WHEN MONTH(ds.DateValue) BETWEEN 7 AND 9 THEN 'FQ2'
                WHEN MONTH(ds.DateValue) BETWEEN 10 AND 12 THEN 'FQ3'
                ELSE 'FQ4'
            END,

            CASE 
                WHEN DATEPART(WEEKDAY, ds.DateValue) IN (1, 7) THEN 'Yes'
                ELSE 'No'
            END,

            NULL,
            NULL,
            @CurrentDatetime,
            @CreatedBy,
            @JobRunId            
        FROM DateSequence ds;

        PRINT 'SP_DIM_DATE executed successfully.';
    END TRY
    BEGIN CATCH
        PRINT 'Error: ' + ERROR_MESSAGE();
        RETURN 1;
    END CATCH
END;