"""Policy decision engine enforcing binding Foundation decisions.

Default is DENY when authorization cannot be established.
"""

from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field

from forge.core.models import (
    ALLOWED_ITEM_PREFIXES,
    APPROVED_WORKSPACES,
    LEGACY_WORKSPACES,
    Environment,
)
from forge.policies.naming import (
    has_banned_fabric_prefix,
    is_dbo_business_object,
    lint_naming_text,
)


class PolicyDecision(str, Enum):
    ALLOW = "ALLOW"
    DENY = "DENY"
    REQUIRES_APPROVAL = "REQUIRES_APPROVAL"


class PolicyResult(BaseModel):
    decision: PolicyDecision
    reasons: list[str] = Field(default_factory=list)
    rule_ids: list[str] = Field(default_factory=list)
    metadata: dict[str, Any] = Field(default_factory=dict)

    @property
    def allowed(self) -> bool:
        return self.decision == PolicyDecision.ALLOW


# Actions that always require independent authorization for production/legacy.
MUTATING_ACTIONS = frozenset(
    {
        "create_item",
        "update_item",
        "delete_item",
        "overwrite_item",
        "disable_item",
        "enable_schedule",
        "deploy_production",
        "mutate_legacy",
        "promote_data_agent",
        "create_capacity",
        "create_warehouse",
        "cutover",
        "backfill_production",
    }
)


class PolicyEngine:
    """Evaluate actor/action/target against Foundation binding decisions."""

    def evaluate_action(
        self,
        actor: str,
        action: str,
        target: dict[str, Any] | None = None,
        environment: str | Environment | None = None,
        evidence: dict[str, Any] | None = None,
        approval: dict[str, Any] | None = None,
    ) -> PolicyResult:
        target = target or {}
        evidence = evidence or {}
        approval = approval or {}
        env = self._normalize_environment(environment, target)
        reasons: list[str] = []

        # D0 / D13 naming gates apply to create/rename style actions.
        object_name = str(target.get("name") or target.get("object_name") or "")
        schema = str(target.get("schema") or "").lower()
        item_type = str(target.get("item_type") or target.get("type") or "")
        workspace = str(target.get("workspace") or target.get("workspace_name") or "")

        if object_name and is_dbo_business_object(schema, object_name, item_type):
            return PolicyResult(
                decision=PolicyDecision.DENY,
                reasons=["Reject new dbo business object (D0/D13)."],
                rule_ids=["D0", "D13", "P-DBO"],
            )

        if object_name and has_banned_fabric_prefix(object_name):
            return PolicyResult(
                decision=PolicyDecision.DENY,
                reasons=[f"Reject banned Fabric/legacy prefix on `{object_name}` (D13)."],
                rule_ids=["D13", "P-PREFIX"],
            )

        naming_hits = lint_naming_text(object_name)
        if naming_hits and action in {"create_item", "rename_item", "create_table", "create_model"}:
            return PolicyResult(
                decision=PolicyDecision.DENY,
                reasons=naming_hits,
                rule_ids=["D13", "P-NAMING"],
            )

        # D4 / D15: no separate Finance warehouse.
        if action == "create_warehouse" and self._is_finance_warehouse(object_name, target):
            return PolicyResult(
                decision=PolicyDecision.DENY,
                reasons=["Reject separate Finance warehouse creation (D4/D15)."],
                rule_ids=["D4", "D15", "P-FINANCE-WAREHOUSE"],
            )

        # D1: Salesforce stays inside Foundation, not a new workspace.
        if action == "create_workspace" and "salesforce" in object_name.lower():
            return PolicyResult(
                decision=PolicyDecision.DENY,
                reasons=["Reject unapproved Salesforce workspace; Salesforce remains inside Foundation (D1)."],
                rule_ids=["D1", "P-SALESFORCE-WS"],
            )

        # D16: data agent promotion requires explicit approval.
        if action == "promote_data_agent":
            if not self._has_item_approval(approval, target):
                return PolicyResult(
                    decision=PolicyDecision.DENY,
                    reasons=["Reject unauthorized data-agent promotion (D16)."],
                    rule_ids=["D16", "P-DATA-AGENT"],
                )

        # Schedules remain disabled until authorized (D12/D18/D19).
        if action == "enable_schedule":
            if not self._has_item_approval(approval, target):
                return PolicyResult(
                    decision=PolicyDecision.DENY,
                    reasons=["Reject schedule activation without item-level approval."],
                    rule_ids=["D12", "D18", "D19", "P-SCHEDULE"],
                )

        # Capacity spend guard.
        if action == "create_capacity":
            if not self._has_item_approval(approval, target):
                return PolicyResult(
                    decision=PolicyDecision.DENY,
                    reasons=["Reject unauthorized capacity creation (FinOps/D12)."],
                    rule_ids=["P-CAPACITY"],
                )

        # D12 production / legacy mutation protection.
        if action in MUTATING_ACTIONS or action.endswith("_production") or action.startswith("prod_"):
            if env in {Environment.FOUNDATION, Environment.LEGACY} or workspace in {
                "Foundation",
                *LEGACY_WORKSPACES,
            }:
                if not self._has_item_approval(approval, target):
                    label = "legacy" if env == Environment.LEGACY or workspace in LEGACY_WORKSPACES else "production"
                    return PolicyResult(
                        decision=PolicyDecision.DENY,
                        reasons=[f"Reject unapproved {label} mutation (D12)."],
                        rule_ids=["D12", "P-PROD-PROTECT"],
                    )

        if action in {"cutover", "modernization_cutover"}:
            if not self._has_item_approval(approval, target):
                return PolicyResult(
                    decision=PolicyDecision.DENY,
                    reasons=["Reject unsupported modernization cutover without authorization (D12)."],
                    rule_ids=["D12", "P-CUTOVER"],
                )

        # Workspace boundary for ordinary engineering mutations.
        if action in {"create_item", "update_item", "deploy"} and workspace:
            if workspace not in APPROVED_WORKSPACES and workspace not in LEGACY_WORKSPACES:
                reasons.append(f"Unknown workspace `{workspace}`; default deny.")
                return PolicyResult(
                    decision=PolicyDecision.DENY,
                    reasons=reasons,
                    rule_ids=["P-WORKSPACE-BOUNDARY"],
                )
            if workspace == "Foundation Governance" and action in {"create_item", "deploy"}:
                dept = str(target.get("folder") or "")
                if dept.startswith("analytics/") and "governance" not in object_name.lower():
                    return PolicyResult(
                        decision=PolicyDecision.DENY,
                        reasons=["Ordinary departmental presentation reports do not belong in Foundation Governance (D17)."],
                        rule_ids=["D17", "P-GOVERNANCE-WS"],
                    )

        # Default: allow read / local / Foundation Development engineering without approval.
        if action.startswith("read") or action in {
            "discover",
            "inventory",
            "validate",
            "lint",
            "compile",
            "dry_run",
            "spec",
            "plan",
        }:
            return PolicyResult(
                decision=PolicyDecision.ALLOW,
                reasons=["Read/analysis action permitted."],
                rule_ids=["P-READ"],
            )

        if env == Environment.FOUNDATION_DEVELOPMENT and action in {
            "create_item",
            "update_item",
            "deploy",
            "create_table",
            "create_model",
        }:
            if object_name and not any(object_name.startswith(p) for p in ALLOWED_ITEM_PREFIXES):
                # Tables and dbt models are not Fabric item prefixes.
                if action not in {"create_table", "create_model"}:
                    return PolicyResult(
                        decision=PolicyDecision.DENY,
                        reasons=[f"`{object_name}` must use an approved Fabric item prefix (D13)."],
                        rule_ids=["D13", "P-PREFIX-REQUIRED"],
                    )
            return PolicyResult(
                decision=PolicyDecision.ALLOW,
                reasons=["Foundation Development engineering action permitted under D12."],
                rule_ids=["D12", "P-FD-ALLOW"],
                metadata={"actor": actor, "evidence_keys": list(evidence.keys())},
            )

        # Authorization cannot be established for the remaining cases.
        return PolicyResult(
            decision=PolicyDecision.DENY,
            reasons=["Default deny: authorization cannot be established for this action."],
            rule_ids=["P-DEFAULT-DENY"],
            metadata={"actor": actor, "action": action, "environment": str(env)},
        )

    @staticmethod
    def _normalize_environment(
        environment: str | Environment | None,
        target: dict[str, Any],
    ) -> Environment:
        if isinstance(environment, Environment):
            return environment
        raw = (environment or target.get("environment") or "").strip().lower()
        mapping = {
            "local": Environment.LOCAL,
            "foundation_development": Environment.FOUNDATION_DEVELOPMENT,
            "foundation development": Environment.FOUNDATION_DEVELOPMENT,
            "fd": Environment.FOUNDATION_DEVELOPMENT,
            "foundation": Environment.FOUNDATION,
            "prod": Environment.FOUNDATION,
            "production": Environment.FOUNDATION,
            "foundation_governance": Environment.FOUNDATION_GOVERNANCE,
            "legacy": Environment.LEGACY,
        }
        workspace = str(target.get("workspace") or target.get("workspace_name") or "")
        if workspace == "Foundation Development":
            return Environment.FOUNDATION_DEVELOPMENT
        if workspace == "Foundation":
            return Environment.FOUNDATION
        if workspace == "Foundation Governance":
            return Environment.FOUNDATION_GOVERNANCE
        if workspace in LEGACY_WORKSPACES:
            return Environment.LEGACY
        return mapping.get(raw, Environment.LOCAL)

    @staticmethod
    def _is_finance_warehouse(name: str, target: dict[str, Any]) -> bool:
        blob = f"{name} {target.get('domain', '')} {target.get('purpose', '')}".lower()
        return ("finance" in blob and "warehouse" in blob) or name.lower() in {
            "warehouse_finance",
            "finance_warehouse",
            "warehouse_finance_analytics",
        }

    @staticmethod
    def _has_item_approval(approval: dict[str, Any], target: dict[str, Any]) -> bool:
        if not approval:
            return False
        if approval.get("authorized") is not True:
            return False
        item = str(target.get("name") or target.get("object_name") or "")
        approved_item = str(approval.get("item") or approval.get("item_name") or "")
        action = str(approval.get("action") or "")
        if not approved_item:
            return False
        if item and approved_item != item:
            return False
        # Written item-level authorization must name the action class.
        return bool(action) or bool(approval.get("explicit_written_authorization"))


def evaluate_action(
    actor: str,
    action: str,
    target: dict[str, Any] | None = None,
    environment: str | Environment | None = None,
    evidence: dict[str, Any] | None = None,
    approval: dict[str, Any] | None = None,
) -> PolicyResult:
    return PolicyEngine().evaluate_action(
        actor=actor,
        action=action,
        target=target,
        environment=environment,
        evidence=evidence,
        approval=approval,
    )
