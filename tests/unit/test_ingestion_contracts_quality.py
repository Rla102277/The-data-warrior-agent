"""Ingestion metadata, contracts, and quality engine tests."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from engineering.data_quality import QualityEngine, QualityOutcome
from forge.contracts import CompatibilityClass, DataContract, SchemaField
from forge.metadata import IngestionLoadType, IngestionSpec, RetryPolicy

ROOT = Path(__file__).resolve().parents[2]


def test_sale_transfer_preserves_truncate_and_load_and_d9_retry() -> None:
    raw = json.loads((ROOT / "tests/fixtures/ingestion/sale_transfer.json").read_text())
    spec = IngestionSpec.model_validate(raw)
    assert spec.load_type == IngestionLoadType.TRUNCATE_AND_LOAD
    assert spec.retry.retry_count == 1
    assert spec.retry.timeout_minutes == 10
    assert spec.schedule_enabled is False
    row = spec.to_control_row()
    assert row["default_load_type"] == "TRUNCATE_AND_LOAD"


def test_dbo_ingestion_rejected() -> None:
    with pytest.raises(ValueError, match="dbo"):
        IngestionSpec(
            spec_id="bad",
            source_system="x",
            source_object="y",
            target_lakehouse_or_warehouse="warehouse_stage",
            target_schema="dbo",
            target_table="customer",
            load_type=IngestionLoadType.FULL,
            retry=RetryPolicy(),
        )


def test_contract_compatibility() -> None:
    base = DataContract(
        contract_id="c1",
        dataset_identity="stage.sale_transfer",
        version="1.0.0",
        owner="foundation",
        business_meaning="Sale transfers",
        schema_fields=[SchemaField(name="id", data_type="int", nullable=False)],
    )
    forward = base.model_copy(
        update={
            "version": "1.1.0",
            "schema_fields": [
                SchemaField(name="id", data_type="int", nullable=False),
                SchemaField(name="note", data_type="string", nullable=True),
            ],
        }
    )
    breaking = base.model_copy(
        update={
            "version": "2.0.0",
            "schema_fields": [SchemaField(name="id", data_type="string", nullable=False)],
        }
    )
    assert base.compare_schema(forward) == CompatibilityClass.FORWARD
    assert base.compare_schema(breaking) == CompatibilityClass.BREAKING


def test_quality_blocks_publication_on_schema_failure() -> None:
    engine = QualityEngine()
    results = engine.evaluate_many(
        ["schema", "uniqueness"],
        {
            "expected_columns": ["id", "amount"],
            "actual_columns": ["id"],
            "duplicate_count": 0,
        },
    )
    assert results[0].outcome == QualityOutcome.BLOCK_PUBLICATION
    assert engine.publication_allowed(results) is False
