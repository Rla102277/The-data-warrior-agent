"""Milestone 2 modernization bar tests."""

from __future__ import annotations

from pathlib import Path

from forge.modernization import assess_adf_pipeline
from forge.policies import PolicyDecision, evaluate_action

FIXTURE = Path("tests/fixtures/adf/sample_pipeline.json")


def test_assess_sample_pipeline_produces_ir_and_decisions() -> None:
    assessment = assess_adf_pipeline(FIXTURE)
    assert assessment.pipeline_name == "pl_legacy_stage_entity_load"
    assert assessment.ir_version == "1.0.0"
    assert assessment.cutover_allowed is False
    decision_ids = {d.decision_id for d in assessment.applicable_decisions}
    assert {"D10", "D12", "D13", "D8", "D9"} <= decision_ids
    assert assessment.dependency_summary["relation_count"] > 0
    assert "dataset:ds_source_entity" in assessment.dependency_summary["inputs"]
    assert assessment.replacement_tests
    assert assessment.evidence_status.value == "CONFIRMED"


def test_cutover_denied_without_approval() -> None:
    result = evaluate_action(
        actor="test",
        action="modernization_cutover",
        target={"workspace": "Foundation", "name": "pl_legacy_stage_entity_load"},
        environment="foundation",
    )
    assert result.decision == PolicyDecision.DENY


def test_d13_rejects_pl_prefix_on_create() -> None:
    result = evaluate_action(
        actor="test",
        action="create_item",
        target={
            "workspace": "Foundation Development",
            "name": "pl_new_thing",
            "item_type": "pipeline",
        },
        environment="foundation_development",
    )
    assert result.decision == PolicyDecision.DENY
