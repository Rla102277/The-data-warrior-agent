CREATE        PROCEDURE control.sp_audit_end
    @audit_type            VARCHAR(20),        -- 'SP' or 'STEP'
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
    @total_record_count    BIGINT = NULL
AS
BEGIN
--SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT ON;

    DECLARE @start_time DATETIME2(3);

    IF @audit_type = 'SP'
    BEGIN
        BEGIN TRANSACTION
            SELECT @start_time = start_time 
            FROM control.audit_sp_control 
            WHERE sp_audit_id = @audit_id;
        COMMIT TRANSACTION;

        EXEC control.sp_update_audit_control
            @audit_type = @audit_type,
            @audit_id = @audit_id,
            @status = @status,
            @error_message = @error_message,
            @records_affected = @records_affected,
            @completed_steps = @completed_steps,
            @failed_step = @failed_step,
            @records_processed = @records_processed,
            @records_inserted = @records_inserted,
            @records_updated = @records_updated,
            @records_deleted = @records_deleted,
            @total_record_count = @total_record_count,
            @start_time = @start_time;

        -- BEGIN TRANSACTION
        --     UPDATE control.audit_sp_control
        --     SET end_time = GETDATE(),
        --         duration_seconds = DATEDIFF(SECOND, @start_time, GETDATE()),
        --         status = @status,
        --         completed_steps = ISNULL(@completed_steps, completed_steps),
        --         failed_step = @failed_step,
        --         error_message = @error_message,
        --         records_processed = @records_processed,
        --         records_inserted = @records_inserted,
        --         records_updated = @records_updated,
        --         records_deleted = @records_deleted
        --     WHERE sp_audit_id = @audit_id;
        -- COMMIT TRANSACTION;
    END

    ELSE IF @audit_type = 'STEP'
    BEGIN
        BEGIN TRANSACTION
            SELECT @start_time = start_time 
            FROM control.audit_step_control 
            WHERE step_audit_id = @audit_id;
        COMMIT TRANSACTION;

        EXEC control.sp_update_audit_control
            @audit_type = @audit_type,
            @audit_id = @audit_id,
            @status = @status,
            @error_message = @error_message,
            @records_affected = @records_affected,
            @completed_steps = @completed_steps,
            @failed_step = @failed_step,
            @records_processed = @records_processed,
            @records_inserted = @records_inserted,
            @records_updated = @records_updated,
            @records_deleted = @records_deleted,
            @start_time = @start_time;

        -- BEGIN TRANSACTION
        --     UPDATE control.audit_step_control
        --     SET end_time = GETDATE(),
        --         duration_seconds = DATEDIFF(SECOND, @start_time, GETDATE()),
        --         status = @status,
        --         records_affected = @records_affected,
        --         error_message = @error_message
        --     WHERE step_audit_id = @audit_id;
        -- COMMIT TRANSACTION;
    END

    ELSE
    BEGIN
        -- THROW is not yet supported in Fabric, use a fallback mechanism
        -- Custom error logic: mark audit type as failed if invalid
        BEGIN TRANSACTION
            UPDATE control.audit_sp_control
            SET status = 'FAILED', 
                error_message = 'Invalid audit_type passed to sp_audit_end'
            WHERE sp_audit_id = @audit_id;
        COMMIT TRANSACTION;
        BEGIN TRANSACTION
            -- If it's a step, also try update that
            UPDATE control.audit_step_control
            SET status = 'FAILED',
                error_message = 'Invalid audit_type passed to sp_audit_end'
            WHERE step_audit_id = @audit_id;
        COMMIT TRANSACTION;
    END
END;