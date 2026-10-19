"""M5: IngestionSpec maps to existing control tables; no parallel DB."""

from __future__ import annotations

import json
from pathlib import Path

from control.ingestion_map import (
    control_plane_decision,
    ingestion_spec_to_stage_load_config,
    stage_load_config_to_ingestion_spec,
)
from control.models import LoadType, StageLoadConfig
from control.repository import StageLoadConfigRepository
from forge.metadata import IngestionLoadType, IngestionSpec, RetryPolicy


def test_control_plane_rejects_parallel_database() -> None:
    decision = control_plane_decision()
    assert decision.parallel_database_allowed is False
    assert "warehouse_stage.control" in decision.store


def test_round_trip_sale_transfer_preserves_d8() -> None:
    spec = IngestionSpec(
        spec_id="ingest_sale_transfer",
        source_system="HBLive",
        source_object="SaleTransfer",
        target_lakehouse_or_warehouse="warehouse_stage",
        target_schema="stage",
        target_table="sale_transfer",
        load_type=IngestionLoadType.TRUNCATE_AND_LOAD,
        retry=RetryPolicy(retry_count=1, timeout_minutes=10),
    )
    row = ingestion_spec_to_stage_load_config(spec)
    assert row.default_load_type == LoadType.TRUNCATE_LOAD
    assert row.retry_count == 1
    assert row.timeout_minutes == 10
    back = stage_load_config_to_ingestion_spec(row, source_system="HBLive")
    assert back.load_type == IngestionLoadType.TRUNCATE_AND_LOAD
    assert back.schedule_enabled is False


def test_seed_fixture_validates_d8_d9() -> None:
    raw = json.loads(Path("tests/fixtures/control/stage_load_config_seed.json").read_text())
    repo = StageLoadConfigRepository()
    for item in raw:
        repo.upsert(StageLoadConfig.model_validate(item))
    problems = repo.validate_d8_d9()
    assert problems == []
