"""Mandatory architectural policy tests (Section 18)."""

from __future__ import annotations

from forge.policies import PolicyDecision, evaluate_action


def test_reject_new_dbo_business_object() -> None:
    result = evaluate_action(
        actor="engineer",
        action="create_table",
        target={
            "workspace": "Foundation Development",
            "name": "customer_obt",
            "schema": "dbo",
            "item_type": "table",
        },
        environment="foundation_development",
    )
    assert result.decision == PolicyDecision.DENY
    assert any("dbo" in reason.lower() for reason in result.reasons)


def test_create_item_does_not_require_a_vendor_prefix() -> None:
    result = evaluate_action(
        actor="engineer",
        action="create_item",
        target={"workspace": "Foundation Development", "name": "orders_daily"},
        environment="foundation_development",
    )
    assert result.decision == PolicyDecision.ALLOW


def test_reject_separate_finance_warehouse() -> None:
    result = evaluate_action(
        actor="engineer",
        action="create_warehouse",
        target={"workspace": "Foundation Development", "name": "warehouse_finance"},
        environment="foundation_development",
    )
    assert result.decision == PolicyDecision.DENY
    assert any("Finance" in reason for reason in result.reasons)


def test_reject_unapproved_salesforce_workspace() -> None:
    result = evaluate_action(
        actor="engineer",
        action="create_workspace",
        target={"name": "gbp-salesforce-prod"},
        environment="foundation_development",
    )
    assert result.decision == PolicyDecision.DENY


def test_reject_unapproved_production_mutation() -> None:
    result = evaluate_action(
        actor="engineer",
        action="update_item",
        target={"workspace": "Foundation", "name": "pipeline_salesforce_ingest"},
        environment="foundation",
    )
    assert result.decision == PolicyDecision.DENY


def test_reject_unapproved_legacy_mutation() -> None:
    result = evaluate_action(
        actor="engineer",
        action="mutate_legacy",
        target={"workspace": "Operations", "name": "legacy_report"},
        environment="legacy",
    )
    assert result.decision == PolicyDecision.DENY


def test_reject_schedule_activation_without_approval() -> None:
    result = evaluate_action(
        actor="engineer",
        action="enable_schedule",
        target={"workspace": "Foundation Development", "name": "pipeline_salesforce_ingest"},
        environment="foundation_development",
    )
    assert result.decision == PolicyDecision.DENY


def test_reject_unauthorized_data_agent_promotion() -> None:
    result = evaluate_action(
        actor="engineer",
        action="promote_data_agent",
        target={"workspace": "Foundation Development", "name": "data_agent_operations_customer_survey"},
        environment="foundation_development",
    )
    assert result.decision == PolicyDecision.DENY


def test_reject_unsupported_modernization_cutover() -> None:
    result = evaluate_action(
        actor="engineer",
        action="cutover",
        target={"workspace": "Foundation", "name": "pipeline_salesforce_ingest"},
        environment="foundation",
    )
    assert result.decision == PolicyDecision.DENY


def test_reject_unauthorized_capacity_creation() -> None:
    result = evaluate_action(
        actor="engineer",
        action="create_capacity",
        target={"name": "unapproved-capacity-02"},
        environment="foundation_development",
    )
    assert result.decision == PolicyDecision.DENY


def test_allow_foundation_development_create_with_approved_prefix() -> None:
    result = evaluate_action(
        actor="engineer",
        action="create_item",
        target={
            "workspace": "Foundation Development",
            "name": "pipeline_salesforce_ingest",
        },
        environment="foundation_development",
    )
    assert result.decision == PolicyDecision.ALLOW
