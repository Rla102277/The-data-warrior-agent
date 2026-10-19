"""First full offline vertical slice: sale_transfer (D8).

Stages: discover control metadata -> build ingestion spec -> validate policy/quality.
Does not deploy and does not enable schedules. The target store is named by the caller.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field

from control.models import LoadType
from control.repository import StageLoadConfigRepository, load_stage_load_config_from_sql
from engineering.data_quality import QualityEngine
from forge.metadata import IngestionLoadType, IngestionSpec, RetryPolicy
from forge.policies import PolicyDecision, evaluate_action


class VerticalSliceResult(BaseModel):
    slice_id: str = "sale_transfer"
    status: str
    stages: dict[str, Any] = Field(default_factory=dict)
    evidence: list[str] = Field(default_factory=list)
    blockers: list[str] = Field(default_factory=list)


_LOAD_MAP = {
    LoadType.TRUNCATE_LOAD: IngestionLoadType.TRUNCATE_AND_LOAD,
    LoadType.FULL: IngestionLoadType.FULL,
    LoadType.AUTO: IngestionLoadType.INCREMENTAL,
    LoadType.INCREMENTAL: IngestionLoadType.INCREMENTAL,
}


def run_sale_transfer_vertical_slice(
    *,
    stage_load_sql: str | Path = "automation/sql/stage_load_config.sql",
    repo: StageLoadConfigRepository | None = None,
) -> VerticalSliceResult:
    evidence: list[str] = []
    stages: dict[str, Any] = {}
    blockers: list[str] = []

    # 1. Discover control metadata
    repository = repo or load_stage_load_config_from_sql(stage_load_sql)
    d8_problems = repository.validate_d8_d9()
    sale = repository.get("sale_transfer")
    stages["discover"] = {
        "active_standard_count": len(repository.list_active()),
        "waves": repository.waves(),
        "sale_transfer": sale.model_dump() if sale else None,
        "d8_d9_problems": d8_problems,
    }
    evidence.append(str(stage_load_sql))
    if sale is None:
        return VerticalSliceResult(
            status="blocked",
            stages=stages,
            evidence=evidence,
            blockers=["sale_transfer missing from control.stage_load_config seed"],
        )
    if d8_problems:
        blockers.extend(d8_problems)

    # 2. Specify ingestion metadata (do not invent incremental for D8 truncate entity)
    spec = IngestionSpec(
        spec_id="ingest_sale_transfer",
        source_system="HBLive",
        source_object=sale.current_name,
        target_workspace="Foundation Development",
        target_lakehouse_or_warehouse="warehouse_stage",
        target_schema="stage",
        target_table=sale.target_name,
        load_type=_LOAD_MAP[sale.default_load_type],
        retry=RetryPolicy(retry_count=sale.retry_count, timeout_minutes=sale.timeout_minutes),
        schedule_enabled=False,
        owner="forge-platform",
        notes="Vertical slice from control.stage_load_config; D8 preserve TRUNCATE_LOAD",
    )
    stages["spec"] = spec.to_control_row()
    evidence.append("forge.metadata.IngestionSpec")

    # 3. Policy validate FD create (not production)
    policy = evaluate_action(
        actor="vertical_slice",
        action="create_table",
        target={
            "workspace": "Foundation Development",
            "name": spec.target_table,
            "schema": "stage",
            "item_type": "table",
        },
        environment="foundation_development",
    )
    stages["policy"] = policy.model_dump()
    if policy.decision != PolicyDecision.ALLOW:
        blockers.extend(policy.reasons)

    prod_policy = evaluate_action(
        actor="vertical_slice",
        action="deploy_production",
        target={"workspace": "Foundation", "name": spec.target_table},
        environment="foundation",
    )
    stages["production_guard"] = prod_policy.model_dump()
    if prod_policy.decision == PolicyDecision.ALLOW:
        blockers.append("production deploy unexpectedly allowed without approval")

    # 4. Quality gate on synthetic metrics (offline)
    quality = QualityEngine().evaluate_many(
        ["schema", "uniqueness", "row_count"],
        {
            "expected_columns": ["sale_transfer_id"],
            "actual_columns": ["sale_transfer_id"],
            "duplicate_count": 0,
            "row_count": 1000,
            "expected_min_rows": 1,
        },
    )
    stages["quality"] = [item.model_dump() for item in quality]
    if not QualityEngine().publication_allowed(quality):
        blockers.append("quality publication blocked")

    status = "passed" if not blockers else "blocked"
    return VerticalSliceResult(
        status=status,
        stages=stages,
        evidence=evidence,
        blockers=blockers,
    )
