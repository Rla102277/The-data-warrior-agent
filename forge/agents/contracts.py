"""Bounded agent role contracts. Agents cannot self-certify production readiness."""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, Field


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class AgentRole(str, Enum):
    SUPERVISOR = "forge_supervisor"
    REQUIREMENTS = "requirements"
    ARCHITECTURE = "architecture"
    DISCOVERY = "discovery"
    FABRIC_ENGINEER = "fabric_engineer"
    METADATA_ENGINEER = "metadata_engineer"
    DBT_ENGINEER = "dbt_engineer"
    MODERNIZATION = "modernization"
    REA_INVESTIGATOR = "rea_investigator"
    DATA_QUALITY = "data_quality"
    SECURITY = "security"
    RELIABILITY = "reliability"
    GOVERNANCE = "governance"
    FINOPS = "finops"
    DOCUMENTATION = "documentation"
    RELEASE = "release"


ROLE_PERMISSIONS: dict[AgentRole, set[str]] = {
    AgentRole.SUPERVISOR: {"coordinate", "read", "assign"},
    AgentRole.REQUIREMENTS: {"spec", "read"},
    AgentRole.ARCHITECTURE: {"architect", "read"},
    AgentRole.DISCOVERY: {"discover", "read", "inventory"},
    AgentRole.FABRIC_ENGINEER: {"build", "read", "validate"},
    AgentRole.METADATA_ENGINEER: {"build", "read", "validate"},
    AgentRole.DBT_ENGINEER: {"build", "read", "validate", "compile"},
    AgentRole.MODERNIZATION: {"assess", "read", "inventory"},
    AgentRole.REA_INVESTIGATOR: {"investigate", "read"},
    AgentRole.DATA_QUALITY: {"validate", "read"},
    AgentRole.SECURITY: {"review", "read"},
    AgentRole.RELIABILITY: {"validate", "read"},
    AgentRole.GOVERNANCE: {"review", "read"},
    AgentRole.FINOPS: {"review", "read"},
    AgentRole.DOCUMENTATION: {"document", "read"},
    AgentRole.RELEASE: {"release_prep", "read"},
}


class AgentTask(BaseModel):
    task_id: str = Field(default_factory=lambda: str(uuid4()))
    role: AgentRole
    objective: str
    inputs: dict[str, Any] = Field(default_factory=dict)
    required_evidence: list[str] = Field(default_factory=list)
    tool_permissions: list[str] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=utc_now)


class AgentTaskResult(BaseModel):
    task_id: str
    role: AgentRole
    status: str
    outputs: dict[str, Any] = Field(default_factory=dict)
    evidence: list[str] = Field(default_factory=list)
    errors: list[str] = Field(default_factory=list)
    self_certified_production: bool = False
    completed_at: datetime = Field(default_factory=utc_now)

    def validate_against_contract(self) -> list[str]:
        problems: list[str] = []
        if self.self_certified_production:
            problems.append("Agents cannot mark their own implementation as production-verified.")
        allowed = ROLE_PERMISSIONS.get(self.role, set())
        for key in self.outputs.get("requested_operations", []):
            if key not in allowed and "*" not in allowed:
                problems.append(f"Role {self.role.value} is not permitted to request `{key}`.")
        return problems
