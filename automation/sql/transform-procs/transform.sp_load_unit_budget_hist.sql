/*
  transform.sp_load_unit_budget_hist
  Durable reload of monthly unit budgets from the harvest landing table
  lake_house_scratch.dbo.unit_budget_hist (copied from Enterprise
  EDW_Silver.dbo.UnitBudgets2025).

  Not on the 15-minute orchestrator. Invoke via
  automation/load_unit_budget_hist.py (harvest then EXEC).
*/

CREATE OR ALTER PROCEDURE transform.sp_load_unit_budget_hist
    @CreatedBy    VARCHAR(100) = 'GB_user',
    @JobRunId     VARCHAR(100) = '',
    @LoadType     VARCHAR(20) = 'TRUNCATE_LOAD',
    @AuditId      VARCHAR(100) = '',
    @OrchestratorAuditId VARCHAR(100) = ''
AS
BEGIN
    SET NOCOUNT ON;

    IF OBJECT_ID('transform.unit_budget_hist') IS NULL
    BEGIN
        CREATE TABLE transform.unit_budget_hist
        (
            ounit   VARCHAR(50)  NOT NULL,
            stat    VARCHAR(50)  NOT NULL,
            amount  FLOAT        NULL,
            [date]  DATE         NOT NULL
        );
    END;

    TRUNCATE TABLE transform.unit_budget_hist;

    INSERT INTO transform.unit_budget_hist (ounit, stat, amount, [date])
    SELECT
        CAST(ounit AS VARCHAR(50)),
        CAST(stat AS VARCHAR(50)),
        CAST(amount AS FLOAT),
        CAST([date] AS DATE)
    FROM lake_house_scratch.dbo.unit_budget_hist;

    SELECT @@ROWCOUNT AS rows_loaded;
END;
