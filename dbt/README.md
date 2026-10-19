# foundation (dbt)

dbt project for the **Foundation Development** Fabric workspace.

## Naming (D13)

| Thing | Name |
|---|---|
| Fabric workspace | `Foundation Development` (keep for deployment pipelines) |
| dbt project | `foundation` |
| Target warehouse | `warehouse_stage` |
| Analytics schema | `analytics` |
| Operations lakehouse | `lake_house_analytics` (shared presentation store) |

Table shape markers (`obt`, `det`, `sum`, `hist`, `map`) are kept. Tool acronyms (`pl_`, `lh_`, `wh_`) are not used for new Fabric artifacts.

## Scope

- **In scope:** analytics / consumption models (`models/analytics/*`)
- **Out of scope for now:** `transform.sp_load_*` (still pipeline-driven)

## Setup

```bash
cd dbt
python -m pip install -r requirements.txt
cp profiles.yml.example ~/.dbt/profiles.yml   # edit if needed
dbt debug
```

Auth uses Azure CLI (`az login`). Database must be the renamed warehouse `warehouse_stage`.

## Commands

```bash
# Preferred when ODBC Driver 18 is installed
dbt run --select analytics

dbt run --select analytics
```

If `dbt debug` fails with missing ODBC driver, use the sql-runner fallback:

```bash
./deploy_via_sql_runner.sh
./deploy_via_sql_runner.sh company lot_events_obt customer_survey_obt sale_obt
```

## Materialization to lakehouse

After dbt deploys `analytics.*` views, `pipeline_operations_analytics_refresh` copies active rows from `control.analytics_refresh_config` into `lake_house_analytics.operations.*`.

`*_active` twins and Gold-name leftovers (`lot_events_det`, `sales_det`, `lot_financials_sum`, `customer_survey_det`, `customer_survey_test_det`) are warehouse wrappers tagged `unpublished`. They are not in the refresh config.

```bash
dbt run --select analytics --exclude tag:unpublished
```

## Source of models

Ported from `automation/sql/analytics-views/`. Prefer editing dbt models going forward; keep the SQL folder in sync until it is retired.
