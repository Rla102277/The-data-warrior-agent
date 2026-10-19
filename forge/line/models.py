"""Typed job and workflow models for Forge Line."""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, Field


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class AutonomyLevel(int, Enum):
    """Safe autonomy levels. Default is Level 2."""

    L0_READ_ONLY = 0
    L1_SPEC_PROPOSE = 1
    L2_BUILD_TEST_ISOLATED = 2
    L3_PR_PROPOSE = 3
    L4_DEPLOY_NONPROD = 4
    L5_NARROW_PROD = 5


class WorkflowStage(str, Enum):
    RECEIVED = "RECEIVED"
    DISCOVERY = "DISCOVERY"
    REQUIREMENTS = "REQUIREMENTS"
    SPECIFICATION = "SPECIFICATION"
    ARCHITECTURE = "ARCHITECTURE"
    PLANNING = "PLANNING"
    BUILDING = "BUILDING"
    CODE_VALIDATION = "CODE_VALIDATION"
    DATA_VALIDATION = "DATA_VALIDATION"
    SECURITY_REVIEW = "SECURITY_REVIEW"
    INDEPENDENT_REVIEW = "INDEPENDENT_REVIEW"
    APPROVAL_PENDING = "APPROVAL_PENDING"
    DEPLOYMENT_READY = "DEPLOYMENT_READY"
    DEPLOYING = "DEPLOYING"
    POST_DEPLOY_VALIDATION = "POST_DEPLOY_VALIDATION"
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    BLOCKED = "BLOCKED"
    CANCELLED = "CANCELLED"
    ROLLBACK_REQUIRED = "ROLLBACK_REQUIRED"


# Valid forward transitions (plus terminal escapes handled in engine).
ALLOWED_TRANSITIONS: dict[WorkflowStage, set[WorkflowStage]] = {
    WorkflowStage.RECEIVED: {WorkflowStage.DISCOVERY, WorkflowStage.CANCELLED, WorkflowStage.FAILED},
    WorkflowStage.DISCOVERY: {
        WorkflowStage.REQUIREMENTS,
        WorkflowStage.BLOCKED,
        WorkflowStage.FAILED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.REQUIREMENTS: {
        WorkflowStage.SPECIFICATION,
        WorkflowStage.BLOCKED,
        WorkflowStage.FAILED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.SPECIFICATION: {
        WorkflowStage.ARCHITECTURE,
        WorkflowStage.BLOCKED,
        WorkflowStage.FAILED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.ARCHITECTURE: {
        WorkflowStage.PLANNING,
        WorkflowStage.BLOCKED,
        WorkflowStage.FAILED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.PLANNING: {
        WorkflowStage.BUILDING,
        WorkflowStage.BLOCKED,
        WorkflowStage.FAILED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.BUILDING: {
        WorkflowStage.CODE_VALIDATION,
        WorkflowStage.BLOCKED,
        WorkflowStage.FAILED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.CODE_VALIDATION: {
        WorkflowStage.DATA_VALIDATION,
        WorkflowStage.BUILDING,  # bounded repair
        WorkflowStage.FAILED,
        WorkflowStage.BLOCKED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.DATA_VALIDATION: {
        WorkflowStage.SECURITY_REVIEW,
        WorkflowStage.BUILDING,
        WorkflowStage.FAILED,
        WorkflowStage.BLOCKED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.SECURITY_REVIEW: {
        WorkflowStage.INDEPENDENT_REVIEW,
        WorkflowStage.BUILDING,  # review rework
        WorkflowStage.FAILED,
        WorkflowStage.BLOCKED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.INDEPENDENT_REVIEW: {
        WorkflowStage.APPROVAL_PENDING,
        WorkflowStage.BUILDING,
        WorkflowStage.FAILED,
        WorkflowStage.BLOCKED,
        WorkflowStage.CANCELLED,
    },
    WorkflowStage.APPROVAL_PENDING: {
        WorkflowStage.DEPLOYMENT_READY,
        WorkflowStage.BUILDING,  # human /factory rework
        WorkflowStage.CANCELLED,
        WorkflowStage.FAILED,
        WorkflowStage.BLOCKED,
    },
    WorkflowStage.DEPLOYMENT_READY: {
        WorkflowStage.DEPLOYING,
        WorkflowStage.CANCELLED,
        WorkflowStage.FAILED,
    },
    WorkflowStage.DEPLOYING: {
        WorkflowStage.POST_DEPLOY_VALIDATION,
        WorkflowStage.ROLLBACK_REQUIRED,
        WorkflowStage.FAILED,
    },
    WorkflowStage.POST_DEPLOY_VALIDATION: {
        WorkflowStage.COMPLETED,
        WorkflowStage.ROLLBACK_REQUIRED,
        WorkflowStage.FAILED,
    },
    WorkflowStage.BLOCKED: {
        WorkflowStage.DISCOVERY,
        WorkflowStage.REQUIREMENTS,
        WorkflowStage.SPECIFICATION,
        WorkflowStage.ARCHITECTURE,
        WorkflowStage.PLANNING,
        WorkflowStage.BUILDING,
        WorkflowStage.CODE_VALIDATION,
        WorkflowStage.DATA_VALIDATION,
        WorkflowStage.SECURITY_REVIEW,
        WorkflowStage.INDEPENDENT_REVIEW,
        WorkflowStage.APPROVAL_PENDING,
        WorkflowStage.CANCELLED,
        WorkflowStage.FAILED,
    },
    WorkflowStage.ROLLBACK_REQUIRED: {WorkflowStage.FAILED, WorkflowStage.CANCELLED, WorkflowStage.COMPLETED},
    WorkflowStage.FAILED: {WorkflowStage.CANCELLED},
    WorkflowStage.CANCELLED: set(),
    WorkflowStage.COMPLETED: set(),
}


class AgentMessage(BaseModel):
    """Typed agent communication contract (ADEF-compatible shape)."""

    message_id: str = Field(default_factory=lambda: str(uuid4()))
    job_id: str
    project_id: str
    agent_id: str
    stage: str
    timestamp: datetime = Field(default_factory=utc_now)
    correlation_id: str = Field(default_factory=lambda: str(uuid4()))
    input_artifacts: list[str] = Field(default_factory=list)
    output_artifacts: list[str] = Field(default_factory=list)
    status: str = "ok"
    findings: list[str] = Field(default_factory=list)
    decisions: list[str] = Field(default_factory=list)
    evidence: list[str] = Field(default_factory=list)
    confidence: float | None = None
    requires_approval: bool = False


class JobState(BaseModel):
    job_id: str = Field(default_factory=lambda: str(uuid4()))
    project_id: str = Field(default_factory=lambda: str(uuid4()))
    title: str
    stage: WorkflowStage = WorkflowStage.RECEIVED
    autonomy_level: AutonomyLevel = AutonomyLevel.L2_BUILD_TEST_ISOLATED
    platform_profile: str = "fabric-first-foundation"
    attempt_count: int = 0
    max_attempts: int = 3
    repair_rounds: int = 0
    max_repair_rounds: int = 2
    assigned_agents: list[str] = Field(default_factory=list)
    input_artifacts: list[str] = Field(default_factory=list)
    output_artifacts: list[str] = Field(default_factory=list)
    validation_evidence: list[str] = Field(default_factory=list)
    error_details: list[str] = Field(default_factory=list)
    approval_decisions: list[dict[str, Any]] = Field(default_factory=list)
    messages: list[AgentMessage] = Field(default_factory=list)
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)
    started_at: datetime | None = None
    ended_at: datetime | None = None
    branch: str | None = None
    worktree_path: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)

    def touch(self) -> None:
        self.updated_at = utc_now()
