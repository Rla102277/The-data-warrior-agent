{{ config(materialized='view', schema='analytics', alias='unit_budget_hist') }}

/*
  Unit budgets (starts/sales/closings/net revenue by operating unit and month).
  Source table: transform.unit_budget_hist
  Origin: GBP-Enterprise EDW_Silver.dbo.UnitBudgets2025.
  Producer: automation/load_unit_budget_hist.py (harvest + transform.sp_load_unit_budget_hist).
  Not on the 15-minute orchestrator.
*/

SELECT
    ounit,
    stat,
    amount,
    [date]
FROM {{ source('transform', 'unit_budget_hist') }}
