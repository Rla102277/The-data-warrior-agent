"""M6 ODCS contract operations."""

from __future__ import annotations

from engineering.contracts import (
    assess_schema_change,
    create_contract,
    evaluate_contract_compliance,
    validate_contract,
)
from forge.contracts.models import CompatibilityClass, SchemaField


def _base(**kwargs):
    data = {
        "contract_id": "cust.obt",
        "dataset_identity": "analytics.customer_obt",
        "version": "1.0.0",
        "owner": "foundation",
        "business_meaning": "Customer one-big-table",
        "schema_fields": [
            SchemaField(name="customer_id", data_type="string", nullable=False),
            SchemaField(name="revenue", data_type="decimal", nullable=False),
        ],
        "keys": ["customer_id"],
        "quality_requirements": ["revenue_non_negative"],
    }
    data.update(kwargs)
    return create_contract(**data)


def test_validate_and_compliance() -> None:
    contract = _base()
    ok, errors = validate_contract(contract)
    assert ok and not errors
    result = evaluate_contract_compliance(
        contract,
        actual_columns=["customer_id", "revenue"],
        row_count=100,
        duplicate_count=0,
    )
    assert result["compliant"] is True


def test_breaking_schema_change_blocks() -> None:
    older = _base()
    newer = _base(
        version="2.0.0",
        schema_fields=[SchemaField(name="customer_id", data_type="int", nullable=False)],
    )
    assessment = assess_schema_change(older, newer)
    assert assessment["compatibility"] == CompatibilityClass.BREAKING.value
    assert assessment["blocking"] is True
