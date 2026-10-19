-- control.parity_check: results of read-only row-count / schema parity
-- between EDW_Silver/Gold (Enterprise) and warehouse_stage (Foundation Development).
-- Populated by automation/parity_check.py. On-demand only; never scheduled.
-- Fabric Warehouse does not support IDENTITY SEED/INCREMENT; use a run-scoped
-- sequence number instead.

IF OBJECT_ID('control.parity_check') IS NULL
BEGIN
    CREATE TABLE control.parity_check (
        run_id              VARCHAR(64)  NOT NULL,
        check_seq           INT          NOT NULL,
        checked_at          DATETIME2(6) NOT NULL,
        layer               VARCHAR(20)  NOT NULL,  -- transform | analytics | control
        edw_object          VARCHAR(200) NOT NULL,  -- e.g. EDW_Silver.dbo.dim_company
        fd_object           VARCHAR(200) NOT NULL,  -- e.g. warehouse_stage.transform.company
        edw_row_count       BIGINT       NULL,
        fd_row_count        BIGINT       NULL,
        row_delta           BIGINT       NULL,
        row_delta_pct       DECIMAL(9,4) NULL,
        column_match        BIT          NULL,      -- 1 = names+order match
        status              VARCHAR(20)  NOT NULL,  -- MATCH | DRIFT | MISSING_EDW | MISSING_FD | ERROR
        notes               VARCHAR(500) NULL
    );
END
GO
