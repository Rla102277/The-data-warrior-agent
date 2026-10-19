/*
  unit_budget_hist
  Source: GBP-Enterprise EDW_Silver.dbo.UnitBudgets2025 (confirmed 2026-08-10)
  Target: warehouse_stage.transform.unit_budget_hist + analytics.unit_budget_hist view
  Refresh: python3 automation/load_unit_budget_hist.py
  (harvest EDW_Silver.dbo.UnitBudgets2025 into lake_house_scratch, then
   EXEC transform.sp_load_unit_budget_hist). Not on the 15-minute orchestrator.
   LotMultiBudget reads HBLive.rems.jobbudgets and does not write this table.
*/

IF OBJECT_ID('transform.unit_budget_hist') IS NOT NULL
    DROP TABLE transform.unit_budget_hist;

CREATE TABLE transform.unit_budget_hist
(
    ounit   VARCHAR(50)  NOT NULL,
    stat    VARCHAR(50)  NOT NULL,
    amount  FLOAT        NULL,
    [date]  DATE         NOT NULL
);

-- Load: use automation/fabsql.py harvest of dbo.UnitBudgets2025 into lake_house_scratch,
-- then generate INSERT batches (see prior load under /tmp/unit_budget_hist_table.sql pattern).

-- View batch must run alone (CREATE VIEW first statement):
-- CREATE VIEW analytics.unit_budget_hist AS
-- SELECT ounit, stat, amount, [date]
-- FROM transform.unit_budget_hist;
