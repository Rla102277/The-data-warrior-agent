/*
  control.stage_load_config seed script
  Target: wh_stage (currently EDW_Silver) on Fabric Warehouse
  Companion docs:
    knowledge/rebuild-plan/rename-map.md          (authoritative rename map, D7)
    knowledge/rebuild-plan/orchestrator-rebuild.md (table-driven orchestration design)

  Schemas: raw | stage | control | transform | analytics
  transform = former silver (conformed entities + dets)
  analytics = former gold (consumption views)
  dbo is not used.

  Purpose:
    - Single metadata table driving pl_stage_orchestrator / pl_stage_wave_runner
    - Doubles as the current_name to target_name rename map applied in Phase 5

  Orchestration model:
    - run_wave: wave N starts after wave N-1 completes; entities within a wave
      run in parallel. Waves derived from the confirmed live orchestrator DAG
      (knowledge/lineage/orchestrator-e2e.md section 3).
    - default_load_type: AUTO (proc watermark logic) | FULL | TRUNCATE_LOAD.
      sale_transfer = TRUNCATE_LOAD and fiscal_period = FULL preserve current
      live behavior at cutover (decision D8 reviews whether to keep them).
    - Validate AUTO faithfully reproduces today's empty-string LoadType before
      cutover (needs proc text; blocked on az MFA refresh).

  View inventory query (run after az MFA refresh, extend rename-map.md with results):
    SELECT s.name AS schema_name, v.name AS view_name
    FROM sys.views v JOIN sys.schemas s ON v.schema_id = s.schema_id
    ORDER BY s.name, v.name;
*/

IF OBJECT_ID('control.stage_load_config') IS NOT NULL
    DROP TABLE control.stage_load_config;

CREATE TABLE control.stage_load_config
(
    target_name         VARCHAR(128)  NOT NULL,  -- new table name per naming standard
    current_name        VARCHAR(128)  NOT NULL,  -- legacy table name (EDW_Silver.dbo); live objects use transform.<target_name>
    schema_name         VARCHAR(32)   NOT NULL,
    shape               VARCHAR(16)   NOT NULL,  -- entity | det | sum | hist | map | obt
    proc_name_current   VARCHAR(128)  NOT NULL,
    proc_name_target    VARCHAR(128)  NOT NULL,
    default_load_type   VARCHAR(32)   NOT NULL,  -- AUTO | FULL | TRUNCATE_LOAD
    watermark_source    VARCHAR(128)  NULL,      -- populate during Phase 3 from proc MaxDateTime logic
    run_group           VARCHAR(16)   NOT NULL,  -- standard | history
    run_wave            INT           NOT NULL,  -- dependency wave within run_group
    timeout_minutes     INT           NOT NULL,
    retry_count         INT           NOT NULL,
    is_active           BIT           NOT NULL,
    notes               VARCHAR(512)  NULL
);

INSERT INTO control.stage_load_config
    (target_name, current_name, schema_name, shape, proc_name_current, proc_name_target,
     default_load_type, watermark_source, run_group, run_wave, timeout_minutes, retry_count, is_active, notes)
VALUES
-- Wave 1: parallel roots (confirmed DAG roots in the live orchestrator)
('company',            'dim_company',        'transform', 'entity', 'sp_load_dim_company',        'sp_load_company',            'AUTO',          NULL, 'standard', 1, 10, 1, 1, NULL),
('division',           'dim_division',       'transform', 'entity', 'sp_load_dim_division',       'sp_load_division',           'AUTO',          NULL, 'standard', 1, 10, 1, 1, NULL),
('operating_unit',     'dim_operating_unit', 'transform', 'entity', 'sp_load_dim_operating_unit', 'sp_load_operating_unit',     'AUTO',          NULL, 'standard', 1, 10, 1, 1, NULL),
('major_minor',        'dim_major_minor',    'transform', 'entity', 'sp_load_dim_major_minor',    'sp_load_major_minor',        'AUTO',          NULL, 'standard', 1, 10, 1, 1, 'REVIEW name: confirm major/minor meaning before sign-off'),
('fiscal_period',      'dim_period',         'transform', 'entity', 'sp_load_dim_period',         'sp_load_fiscal_period',      'FULL',          NULL, 'standard', 1, 10, 1, 1, 'FULL preserves current hard-coded behavior; review under D8. REVIEW name: assumes period = fiscal period'),
('project',            'dim_project',        'transform', 'entity', 'sp_load_dim_project',        'sp_load_project',            'AUTO',          NULL, 'standard', 1, 10, 1, 1, NULL),
('job_task',           'dim_job_task',       'transform', 'entity', 'sp_load_dim_job_task',       'sp_load_job_task',           'AUTO',          NULL, 'standard', 1, 10, 1, 1, 'dim_job_task1 / dim_job_task2 are deleted in Phase 1, not migrated'),
('sale_transfer',      'dim_sale_transfer',  'transform', 'entity', 'sp_load_dim_sale_transfer',  'sp_load_sale_transfer',      'TRUNCATE_LOAD', NULL, 'standard', 1, 10, 1, 1, 'TRUNCATE_LOAD preserves current hard-coded behavior; review under D8'),
('general_ledger_det', 'fact_general_ledger','transform', 'det',    'sp_load_fact_general_ledger','sp_load_general_ledger_det', 'AUTO',          NULL, 'standard', 1, 10, 1, 1, NULL),
('calendar',           'dim_date',           'transform', 'entity', 'sp_load_dim_date',           'sp_load_calendar',           'AUTO',          NULL, 'standard', 1, 10, 1, 0, 'Proc exists but nothing invokes it today (confirmed gap); activate after validation'),

-- Wave 2
('job',                    'dim_job',     'transform', 'entity', 'sp_load_dim_job',     'sp_load_job',                    'AUTO', NULL, 'standard', 2, 10, 1, 1, 'Depends on job_task'),
('sales_gross_margin_map', 'dim_sgm_map', 'transform', 'map',    'sp_load_dim_sgm_map', 'sp_load_sales_gross_margin_map', 'AUTO', NULL, 'standard', 2, 10, 1, 1, 'Depends on major_minor. REVIEW name: confirm SGM = sales gross margin'),

-- Wave 3
('sale',               'dim_sale',            'transform', 'entity', 'sp_load_dim_sale',            'sp_load_sale',               'AUTO', NULL, 'standard', 3, 10, 1, 1, 'Depends on sale_transfer + job'),
('lot_financials_det', 'fact_lot_financials', 'transform', 'det',    'sp_load_fact_lot_financials', 'sp_load_lot_financials_det', 'AUTO', NULL, 'standard', 3, 10, 1, 1, 'Depends on general_ledger + sales_gross_margin_map'),

-- Wave 4
('lot', 'dim_lot', 'transform', 'entity', 'sp_load_dim_lot', 'sp_load_lot', 'AUTO', NULL, 'standard', 4, 10, 1, 1, 'Depends on sale'),

-- Wave 5
('sales_gross_margin_assumptions_det', 'fact_sgm_assumptions', 'transform', 'det', 'sp_load_fact_sgm_assumptions', 'sp_load_sales_gross_margin_assumptions_det', 'AUTO', NULL, 'standard', 5, 10, 1, 1, 'Depends on lot + lot_financials + project. REVIEW name: SGM expansion'),

-- Wave 6
('lot_sales_gross_margin_det', 'fact_lot_sgm', 'transform', 'det', 'sp_load_fact_lot_sgm', 'sp_load_lot_sales_gross_margin_det', 'AUTO', NULL, 'standard', 6, 10, 1, 1, 'Depends on sales_gross_margin_assumptions. REVIEW name: SGM expansion'),

-- On-demand monthly budgets (not 15-minute). Run automation/load_unit_budget_hist.py
('unit_budget_hist', 'UnitBudgets2025', 'transform', 'hist', 'sp_load_unit_budget_hist', 'sp_load_unit_budget_hist', 'TRUNCATE_LOAD', NULL, 'standard', 7, 10, 1, 0, 'Harvest EDW_Silver.dbo.UnitBudgets2025 then EXEC transform.sp_load_unit_budget_hist. is_active=0 keeps it off the 15-min orchestrator.'),

-- History run group (on demand via pl_stage_orchestrator p_run_group = 'history';
-- replaces pp_fact_hist_scheduled chain, expired since 2025-12-31)
('lot_financials_hist',                 'fact_lot_financials_hist',  'transform', 'hist', 'sp_load_fact_lot_financials_hist',  'sp_load_lot_financials_hist',                 'AUTO', NULL, 'history', 1, 15, 1, 1, NULL),
('lot_sales_gross_margin_hist',         'fact_lot_sgm_hist',         'transform', 'hist', 'sp_load_fact_lot_sgm_hist',         'sp_load_lot_sales_gross_margin_hist',         'AUTO', NULL, 'history', 1, 15, 1, 1, 'REVIEW name: SGM expansion'),
('sales_gross_margin_assumptions_hist', 'fact_sgm_assumptions_hist', 'transform', 'hist', 'sp_load_fact_sgm_assumptions_hist', 'sp_load_sales_gross_margin_assumptions_hist', 'AUTO', NULL, 'history', 1, 15, 1, 1, 'REVIEW name: SGM expansion');

-- Not seeded (dispositions per rename-map.md):
--   dim_job_task1, dim_job_task2  : DELETE in Phase 1
--   UnitBudgets2025               : unit_budget_hist; on-demand harvest+proc (is_active=0)
--   tbl_Milestones                : RENAME milestone (or lot_milestones_det), no load proc observed
--   control.vw_pipeline_performance_summary : view, renames to control.pipeline_performance_sum
