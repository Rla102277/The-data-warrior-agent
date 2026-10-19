CREATE      PROCEDURE control.sp_audit_start
    @audit_id              VARCHAR(100),
    @orchestrator_audit_id VARCHAR(100) = NULL,
    @pipeline_audit_id     VARCHAR(100) = NULL,
    @audit_type            VARCHAR(20),        -- 'SP' or 'STEP'
    @pipeline_run_id       VARCHAR(100) = NULL,
    @procedure_name        VARCHAR(100) = NULL,
    @load_type             VARCHAR(20) = NULL,
    @max_date_time         VARCHAR(100) = NULL,
    @created_by            VARCHAR(100) = NULL,
    @total_steps           INT = NULL,
    @step_number           INT = NULL,         -- Required for STEP type
    @step_name             VARCHAR(200) = NULL,-- Required for STEP type
    @step_description      VARCHAR(500) = NULL,
    @return_id             BIGINT OUTPUT       -- Returns step_audit_id
AS
BEGIN
--SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT ON;
    DECLARE @start_time DATETIME2(3) = GETDATE();
    IF @audit_type = 'SP'
    BEGIN

        --DECLARE @new_sp_audit_id BIGINT = CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), GETDATE())));
        BEGIN TRANSACTION
            INSERT INTO control.audit_sp_control ( --pipeline_audit_id and sp_audit_id are same as the have 1 to 1 refrence 
                sp_audit_id,orchestrator_audit_id,pipeline_audit_id/*,pipeline_run_id*/, procedure_name, load_type, max_date_time, 
                created_by, start_time, created_date, total_steps, status
            )
            VALUES (
                @audit_id,@orchestrator_audit_id,@pipeline_audit_id/*,@pipeline_run_id*/, @procedure_name, @load_type, @max_date_time,
                @created_by, @start_time, @start_time, @total_steps, 'RUNNING'
            );
        COMMIT TRANSACTION;

        SET @return_id = @audit_id;
    END
    ELSE IF @audit_type = 'STEP'
    BEGIN
        -- Generate unique surrogate key manually
        DECLARE @new_step_audit_id BIGINT = CONVERT(BIGINT, CONVERT(VARBINARY, CONCAT(NEWID(), @start_time)));
        BEGIN TRANSACTION
            INSERT INTO control.audit_step_control (
                step_audit_id, sp_audit_id, step_number, step_name, step_description, 
                start_time, created_date, status
            )
            VALUES (
                @new_step_audit_id, @audit_id, @step_number, @step_name, @step_description,
                @start_time, @start_time, 'RUNNING'
            );
        COMMIT TRANSACTION;
        
        SET @return_id = @new_step_audit_id;

        BEGIN TRANSACTION
        -- Update sp run with current step progress
            /*UPDATE control.audit_sp_control
            SET completed_steps = @step_number - 1
            WHERE sp_audit_id = @audit_id;*/
        COMMIT TRANSACTION;
    END
    ELSE
    BEGIN
        -- Fabric doesn't support THROW or RAISERROR, use a status update to log issue
        DECLARE @error_msg VARCHAR(200) = 'Invalid audit_type. Must be either SP or STEP.';

        -- Optional: You can log the error into a separate error audit table

        -- Fail-safe fallback logging
        IF @audit_id IS NOT NULL
        BEGIN
            BEGIN TRANSACTION
                UPDATE control.audit_sp_control
                SET status = 'FAILED', error_message = @error_msg
                WHERE sp_audit_id = @audit_id;
            COMMIT TRANSACTION;
        END
        SET @return_id = NULL;
    END
END;