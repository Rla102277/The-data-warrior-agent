"""Run local Foundation-layered demo with independent reconciliation."""

from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any

from demos.local_orders.generate_source import generate
from engineering.contracts import create_contract, evaluate_contract_compliance, validate_contract
from engineering.data_quality.duckdb_engine import DuckDbQualityEngine
from forge.line import JobStore, WorkflowEngine, WorkflowStage
from forge.line.models import AgentMessage
from forge.contracts.models import SchemaField

ROOT = Path(__file__).resolve().parent
DATA = ROOT / "data"


def _read_csv(path: Path) -> list[dict[str, str]]:
    with path.open() as handle:
        return list(csv.DictReader(handle))


def _write_csv(path: Path, rows: list[dict[str, Any]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def transform() -> dict[str, Any]:
    raw = generate()
    customers = {r["customer_id"]: r for r in _read_csv(raw / "customers.csv")}
    orders_raw = _read_csv(raw / "orders.csv")
    returns = _read_csv(raw / "returns.csv")

    seen: set[str] = set()
    stage_orders: list[dict[str, Any]] = []
    quarantine: list[dict[str, Any]] = []
    for row in orders_raw:
        if not row.get("customer_id") or row["customer_id"] not in customers:
            quarantine.append({**row, "reason": "missing_or_unknown_customer"})
            continue
        if row["order_id"] in seen:
            quarantine.append({**row, "reason": "duplicate_order_id"})
            continue
        seen.add(row["order_id"])
        stage_orders.append(row)

    _write_csv(
        DATA / "stage" / "orders.csv",
        stage_orders,
        ["order_id", "customer_id", "amount", "order_ts"],
    )
    _write_csv(
        DATA / "stage" / "quarantine_orders.csv",
        quarantine,
        ["order_id", "customer_id", "amount", "order_ts", "reason"],
    )

    sales = [
        {
            "order_id": o["order_id"],
            "customer_id": o["customer_id"],
            "amount": float(o["amount"]),
        }
        for o in stage_orders
    ]
    _write_csv(DATA / "transform" / "sales_det.csv", sales, ["order_id", "customer_id", "amount"])

    return_amt = {r["order_id"]: float(r["amount"]) for r in returns}
    gross = sum(s["amount"] for s in sales)
    returned = sum(return_amt.values())
    analytics = {
        "order_count": len(sales),
        "unique_customers": len({s["customer_id"] for s in sales}),
        "gross_revenue": round(gross, 2),
        "return_count": len(returns),
        "net_revenue": round(gross - returned, 2),
    }
    (DATA / "analytics").mkdir(parents=True, exist_ok=True)
    (DATA / "analytics" / "sales_sum_daily.json").write_text(json.dumps(analytics, indent=2))
    return {
        "analytics": analytics,
        "quarantine_count": len(quarantine),
        "stage_order_count": len(stage_orders),
    }


def run() -> dict[str, Any]:
    engine = WorkflowEngine(JobStore(ROOT / "factory_jobs"))
    job = engine.create_job(
        "local orders foundation demo",
        platform_profile="fabric-first-foundation",
        metadata={"demo": "local_orders"},
    )
    # Advance through build/code validation; data validation waits on independent fixtures.
    job = engine.advance_happy_path(job, stop_before=WorkflowStage.DATA_VALIDATION)

    result = transform()
    expected = json.loads((ROOT / "expected_aggregates.json").read_text())
    quality = DuckDbQualityEngine()
    recon = quality.reconcile_aggregates(actual=result["analytics"], expected=expected)

    contract = create_contract(
        contract_id="analytics.sales_sum_daily",
        dataset_identity="analytics.sales_sum_daily",
        version="1.0.0",
        owner="foundation",
        business_meaning="Daily sales summary mart",
        schema_fields=[
            SchemaField(name="order_count", data_type="int", nullable=False),
            SchemaField(name="gross_revenue", data_type="decimal", nullable=False),
            SchemaField(name="net_revenue", data_type="decimal", nullable=False),
        ],
        keys=["order_count"],
        quality_requirements=["match_independent_expected_aggregates"],
    )
    ok, errs = validate_contract(contract)
    compliance = evaluate_contract_compliance(
        contract,
        actual_columns=list(result["analytics"].keys()),
        row_count=1,
    )

    engine.store.write_artifact(job.job_id, "demo-report.json", json.dumps({
        "result": result,
        "expected": expected,
        "reconciliation": recon.model_dump(),
        "contract_valid": ok,
        "contract_errors": errs,
        "compliance": compliance,
    }, indent=2))
    job = engine.record_message(
        job,
        AgentMessage(
            job_id=job.job_id,
            project_id=job.project_id,
            agent_id="demo-runner",
            stage=job.stage.value,
            output_artifacts=["demo-report.json"],
            evidence=["demos/local_orders/expected_aggregates.json"],
            findings=[recon.message],
            status="ok" if recon.outcome.value == "PASS" else "fail",
        ),
    )
    if recon.outcome.value == "PASS" and compliance["compliant"] and ok:
        job = engine.transition(job, WorkflowStage.DATA_VALIDATION, reason="demo quality passed")
        job = engine.transition(job, WorkflowStage.SECURITY_REVIEW, reason="demo security gate")
        job = engine.transition(job, WorkflowStage.INDEPENDENT_REVIEW, reason="independent fixtures")
        job = engine.transition(job, WorkflowStage.APPROVAL_PENDING, reason="await human")
        status = "passed"
    else:
        job = engine.transition(job, WorkflowStage.DATA_VALIDATION, reason="quality attempted")
        job = engine.transition(job, WorkflowStage.FAILED, reason=recon.message)
        status = "failed"

    return {
        "status": status,
        "job_id": job.job_id,
        "stage": job.stage.value,
        "analytics": result["analytics"],
        "reconciliation": recon.model_dump(),
        "quarantine_count": result["quarantine_count"],
    }


if __name__ == "__main__":
    print(json.dumps(run(), indent=2))
