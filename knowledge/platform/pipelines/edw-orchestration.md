# EDW staging load and orchestration

**Documented:** 2026-07-15
**Workspace:** GBP-Enterprise

## Pattern (Confirmed)

- `pp_load_stg_to_dim_<entity>` (base)
- `pp_load_stg_to_dim_<entity>_audit`
- `pp_load_stg_to_dim_<entity>_full`
- `pp_load_stg_to_dim_<entity>_no_audit`
- Same suffixes for `pp_load_stg_to_fact_<entity>`
- History: `pp_load_stg_to_fact_<entity>_hist` and `pp_load_fact_*_hist`

Typical activity mix across estate: SetVariable, Script, SqlServerStoredProcedure, Lookup, InvokePipeline, Copy, IfCondition.

## Dimension entities and variants

| Entity | base | audit | full | no_audit |
|---|---|---|---|---|
| company | Y | Y | Y | Y |
| division | Y | Y | Y | Y |
| job | Y | Y | Y | Y |
| job_task | Y | Y | Y | Y |
| lot | Y | Y | Y | Y |
| major_minor | Y | Y | Y | Y |
| operating_unit | Y | Y | Y | Y |
| period | Y | Y | - | Y |
| project | Y | Y | Y | Y |
| sale | Y | Y | Y | Y |
| sale_transfer | Y | Y | - | Y |
| sgm_map | Y | Y | Y | Y |

## Fact entities and variants

| Entity | base | audit | full | no_audit | hist |
|---|---|---|---|---|---|
| general_ledger | Y | Y | Y | Y | - |
| lot_financials | Y | Y | Y | Y | Y |
| lot_sgm | Y | Y | Y | Y | Y |
| sgm_assumptions | Y | Y | Y | Y | Y |

## Orchestrators (non-Salesforce)

### `pp_fact_hist_scheduled` (`21040099-0634-44a1-a532-c21927b49c3c`)
- Schedule: ON Daily @00:00 (Central Standard Time; end 2025-12-31)
- Runs: 0 tot / 0 ok / 0 fail
- Child pipeline order:
  1. **fact_lot_financials_hist** -> `pp_load_fact_lot_financials_to_fact_lot_financials_hist`
  1. **fact_sgm_assumptions_hist** -> `pp_load_fact_sgm_assumptions_to_fact_sgm_assumptions_hist`
  1. **fact_lot_sgm_hist** -> `pp_load_fact_lot_sgm_to_fact_lot_sgm_hist`

### `pp_orchestration` (`17465852-a4ab-492e-b950-1050ed800d74`)
- Schedule: off Cron every 15m (Central Standard Time; end 2025-12-31)
- Runs: 0 tot / 0 ok / 0 fail
- Child pipeline order:
  1. **dim_job_task** -> `pp_load_stg_to_dim_job_task`
  1. **dim_sale_transfer** -> `pp_load_stg_to_dim_sale_transfer`
  1. **dim_job** -> `pp_load_stg_to_dim_job`
  1. **dim_sale** -> `pp_load_stg_to_dim_sale`
  1. **dim_lot** -> `pp_load_stg_to_dim_lot`
  1. **dim_major_minor** -> `pp_load_stg_to_dim_major_minor`
  1. **fact_general_ledger** -> `pp_load_stg_to_fact_general_ledger`
  1. **dim_sgm_map** -> `pp_load_stg_to_dim_sgm_map`
  1. **fact_lot_financials** -> `pp_load_stg_to_fact_lot_financials`
  1. **dim_company** -> `pp_load_stg_to_dim_company`
  1. **dim_division** -> `pp_load_stg_to_dim_division`
  1. **dim_period** -> `pp_load_stg_to_dim_period`
  1. **dim_operating_unit** -> `pp_load_stg_to_dim_operating_unit`
  1. **dim_project** -> `pp_load_stg_to_dim_project`

### `pp_orchestration_full` (`22b96108-4107-427c-a468-80e8acbb1286`)
- Schedule: none
- Runs: 3 tot / 3 ok / 0 fail
- Child pipeline order:
  1. **dim_job_task** -> `pp_load_stg_to_dim_job_task_full`
  1. **dim_sale_transfer** -> `pp_load_stg_to_dim_sale_transfer_audit`
  1. **dim_job** -> `pp_load_stg_to_dim_job_full`
  1. **dim_sale** -> `pp_load_stg_to_dim_sale_full`
  1. **dim_lot** -> `pp_load_stg_to_dim_lot_full`
  1. **dim_major_minor** -> `pp_load_stg_to_dim_major_minor_full`
  1. **fact_general_ledger** -> `pp_load_stg_to_fact_general_ledger_full`
  1. **dim_sgm_map** -> `pp_load_stg_to_dim_sgm_map_full`
  1. **fact_lot_financials** -> `pp_load_stg_to_fact_lot_financials_full`
  1. **dim_company** -> `pp_load_stg_to_dim_company_full`
  1. **dim_division** -> `pp_load_stg_to_dim_division_full`
  1. **dim_period** -> `pp_load_stg_to_dim_period_audit`
  1. **dim_operating_unit** -> `pp_load_stg_to_dim_operating_unit_full`
  1. **dim_project** -> `pp_load_stg_to_dim_project_full`
  1. **fact_sgm_assumptions** -> `pp_load_stg_to_fact_sgm_assumptions_full`
  1. **fact_lot sgm** -> `pp_load_stg_to_fact_lot_sgm_full`

### `pp_orchestration_with_pp_audit` (`e9201dd4-fccb-4e42-8884-64970fb5fa6e`)
- Schedule: off Cron every 30m (Central Standard Time; end 2026-12-17)
- Runs: 0 tot / 0 ok / 0 fail
- Child pipeline order:
  1. **dim_job_task** -> `pp_load_stg_to_dim_job_task_audit`
  1. **dim_sale_transfer** -> `pp_load_stg_to_dim_sale_transfer_audit`
  1. **dim_job** -> `pp_load_stg_to_dim_job_audit`
  1. **dim_sale** -> `pp_load_stg_to_dim_sale_audit`
  1. **dim_lot** -> `pp_load_stg_to_dim_lot_audit`
  1. **dim_major_minor** -> `pp_load_stg_to_dim_major_minor_audit`
  1. **fact_general_ledger** -> `pp_load_stg_to_fact_general_ledger_audit`
  1. **dim_sgm_map** -> `pp_load_stg_to_dim_sgm_map_audit`
  1. **fact_lot_financials** -> `pp_load_stg_to_fact_lot_financials_audit`
  1. **dim_company** -> `pp_load_stg_to_dim_company_audit`
  1. **dim_division** -> `pp_load_stg_to_dim_division_audit`
  1. **dim_period** -> `pp_load_stg_to_dim_period_audit`
  1. **dim_operating_unit** -> `pp_load_stg_to_dim_operating_unit_audit`
  1. **dim_project** -> `pp_load_stg_to_dim_project_audit`
  1. **fact_sgm_assumptions** -> `pp_load_stg_to_fact_sgm_assumptions_audit`
  1. **fact_lot_sgm** -> `pp_load_stg_to_fact_lot_sgm_audit`

### `pp_orchestrator_test` (`678c340c-0df7-4118-90ee-4e21bda10657`)
- Schedule: off Cron every 15m (India Standard Time; end 2025-07-28)
- Runs: 0 tot / 0 ok / 0 fail
- Child pipeline order:
  1. **dim_job_task** -> `pp_load_stg_to_dim_job_task`
  1. **dim_sale_transfer** -> `pp_load_stg_to_dim_sale_transfer`
  1. **dim_job** -> `pp_load_stg_to_dim_job`
  1. **dim_sale** -> `pp_load_stg_to_dim_sale`
  1. **dim_lot** -> `pp_load_stg_to_dim_lot`
  1. **dim_major_minor** -> `pp_load_stg_to_dim_major_minor`
  1. **fact_general_ledger** -> `pp_load_stg_to_fact_general_ledger`
  1. **dim_sgm_map** -> `pp_load_stg_to_dim_sgm_map`
  1. **fact_lot_financials** -> `pp_load_stg_to_fact_lot_financials`
  1. **dim_company** -> `pp_load_stg_to_dim_company`
  1. **dim_division** -> `pp_load_stg_to_dim_division`
  1. **dim_period** -> `pp_load_stg_to_dim_period`
  1. **dim_operating_unit** -> `pp_load_stg_to_dim_operating_unit`
  1. **dim_project** -> `pp_load_stg_to_dim_project`

## Notes

- `pp_orchestration_without_pp_audit` has an enabled Cron every 15 minutes (Central).
- Several schedules show enabled=true but endDateTime in 2025 (expired); treat as inactive until extended.
- `pp_load_stg_to_dim_period` and `pp_load_stg_to_dim_sale_transfer` have no `_full` variant in the live list.
- Deeper proc/variant analysis: `edw-deep-dive.md`. Schedule status: `schedule-truth-table.md`. Lineage: `../lineage/overview.md`.
