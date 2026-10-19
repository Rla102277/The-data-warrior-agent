#!/usr/bin/env bash
# Render dbt analytics models (source/ref -> SQL names) and deploy via pipeline_sql_runner.
# Used when local ODBC / dbt-fabric connection to warehouse_stage is unavailable.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SELECTS="${*:-company division operating_unit fiscal_period major_minor plan project lot job job_task sale sale_transfer calendar lot_financials_det lot_financials_obt lot_obt sale_obt lot_events_obt sales_sum_weekly sales_sum_monthly unit_sum_weekly customer_survey_obt sales_gross_margin_map sales_gross_margin_assumptions_det general_ledger_det lot_sales_gross_margin_det unit_budget_hist title_booking_obt title_communities_det web_listing_obt web_community web_plan web_lot competitor_listing_obt competitor_community_obt}"

python3 << PY
import re, sys
from pathlib import Path
sys.path.insert(0, "$ROOT/automation")
from fabsql import sql

models_dir = Path("$ROOT/dbt/models/analytics")
names = """$SELECTS""".split()

def render(text: str) -> str:
    # strip config
    text = re.sub(r"\{\{\s*config\([^}]*(?:\{[^}]*\}[^}]*)*\)\s*\}\}", "", text, count=1)
    text = re.sub(r"\{\{\s*source\(\s*'transform'\s*,\s*'([^']+)'\s*\)\s*\}\}", r"transform.\1", text)
    text = re.sub(r"\{\{\s*source\(\s*'raw'\s*,\s*'([^']+)'\s*\)\s*\}\}", r"raw.\1", text)
    text = re.sub(r"\{\{\s*source\(\s*'control'\s*,\s*'([^']+)'\s*\)\s*\}\}", r"control.\1", text)
    text = re.sub(r"\{\{\s*source\(\s*'dataverse'\s*,\s*'([^']+)'\s*\)\s*\}\}", r"dataverse_gbpdev.dbo.\1", text)
    text = re.sub(r"\{\{\s*ref\(\s*'([^']+)'\s*\)\s*\}\}", r"analytics.[\1]", text)
    return text.strip().rstrip(";")

ok = fail = 0
for name in names:
    path = models_dir / f"{name}.sql"
    if not path.exists():
        print("MISSING", name); fail += 1; continue
    body = render(path.read_text())
    ddl = f"CREATE OR ALTER VIEW analytics.[{name}] AS\n{body};"
    print("deploy", name, flush=True)
    status, reason = sql(ddl, 900)
    print(" ", status, (str(reason)[:200] if reason else ""))
    if status == "Completed":
        ok += 1
    else:
        fail += 1
print(f"done ok={ok} fail={fail}")
if fail:
    sys.exit(1)
PY
