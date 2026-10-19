CREATE      PROCEDURE control.sp_update_audit_control
    @audit_type            VARCHAR(20),
    @audit_id              BIGINT,             -- pipeline_run_id or step_audit_id
    @status                VARCHAR(20),        -- SUCCESS, FAILED
    @error_message         VARCHAR(4000) = NULL,
    @records_affected      BIGINT = NULL,
    @completed_steps       INT = NULL,
    @failed_step           INT = NULL,
    @records_processed     BIGINT = NULL,
    @records_inserted      BIGINT = NULL,
    @records_updated       BIGINT = NULL,
    @records_deleted       BIGINT = NULL,
    @total_record_count    BIGINT = NULL,
    @start_time            DATETIME2(3)
AS
BEGIN
    DECLARE @retry_count INT = 0;
    DECLARE @max_retries INT = 5;
    DECLARE @wait_seconds VARCHAR(8) = '00:00:01';
    IF @audit_type = 'SP'
    BEGIN
        WHILE @retry_count < @max_retries
            BEGIN TRY
                UPDATE control.audit_sp_control
                SET end_time = GETDATE(),
                    duration_seconds = DATEDIFF(SECOND, @start_time, GETDATE()),
                    status = @status,
                    completed_steps = ISNULL(@completed_steps, completed_steps),
                    failed_step = @failed_step,
                    error_message = @error_message,
                    records_processed = @records_processed,
                    records_inserted = @records_inserted,
                    records_updated = @records_updated,
                    records_deleted = @records_deleted,
                    total_record_count = @total_record_count
                WHERE sp_audit_id = @audit_id;
                BREAK;
            END TRY
            BEGIN CATCH
                IF ERROR_MESSAGE() LIKE '%Snapshot isolation transaction %'  -- Snapshot isolation conflict
                BEGIN
                    SET @retry_count += 1;
                    SET @wait_seconds = CONCAT('00:00:',RIGHT('0' + CAST(ABS(CHECKSUM(NEWID())) % 6 + 3 AS VARCHAR), 2));
                    --SET @wait_seconds = CONCAT('00:00:',RIGHT('0' + CAST(@retry_count AS VARCHAR), 2));
                    WAITFOR DELAY @wait_seconds; -- wait 1 second before retry
                END
                ELSE
                BEGIN
                    THROW; -- other errors
                END
            END CATCH
    END

    ELSE IF @audit_type = 'STEP'
    BEGIN
        WHILE @retry_count < @max_retries
            BEGIN TRY
                UPDATE control.audit_step_control
                SET end_time = GETDATE(),
                    duration_seconds = DATEDIFF(SECOND, @start_time, GETDATE()),
                    status = @status,
                    records_affected = @records_affected,
                    error_message = @error_message
                WHERE step_audit_id = @audit_id;
                BREAK;
            END TRY
            BEGIN CATCH
                IF ERROR_MESSAGE() LIKE '%Snapshot isolation transaction %'
                BEGIN
                    SET @retry_count += 1;
                    SET @wait_seconds = CONCAT('00:00:',RIGHT('0' + CAST(ABS(CHECKSUM(NEWID())) % 6 + 3 AS VARCHAR), 2));
                    --SET @wait_seconds = CONCAT('00:00:',RIGHT('0' + CAST(@retry_count AS VARCHAR), 2));
                    WAITFOR DELAY @wait_seconds;
                END
                ELSE
                BEGIN
                    THROW;  -- re-throw for other errors
                END
            END CATCH
    END
END