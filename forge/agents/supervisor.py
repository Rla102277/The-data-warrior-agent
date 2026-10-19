"""Deterministic supervisor state machine for Foundation workflows.

Persists progress to disk so chat context is not the only memory.
Does not bypass policy evaluation for privileged actions.
"""

from __future__ import annotations

from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, Field

from forge.agents.contracts import AgentRole, AgentTask, AgentTaskResult
from forge.exceptions import PolicyDeniedError, ValidationError
from forge.policies import PolicyDecision, evaluate_action


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


class WorkflowStage(str, Enum):
    RECEIVED = "received"
    DISCOVER = "discover"
    SPEC = "spec"
    PLAN = "plan"
    BUILD = "build"
    VALIDATE = "validate"
    REVIEW = "review"
    SHIP = "ship"
    BLOCKED = "blocked"
    COMPLETED = "completed"


STAGE_ORDER = [
    WorkflowStage.RECEIVED,
    WorkflowStage.DISCOVER,
    WorkflowStage.SPEC,
    WorkflowStage.PLAN,
    WorkflowStage.BUILD,
    WorkflowStage.VALIDATE,
    WorkflowStage.REVIEW,
    WorkflowStage.SHIP,
    WorkflowStage.COMPLETED,
]

STAGE_ROLE: dict[WorkflowStage, AgentRole] = {
    WorkflowStage.DISCOVER: AgentRole.DISCOVERY,
    WorkflowStage.SPEC: AgentRole.REQUIREMENTS,
    WorkflowStage.PLAN: AgentRole.ARCHITECTURE,
    WorkflowStage.BUILD: AgentRole.FABRIC_ENGINEER,
    WorkflowStage.VALIDATE: AgentRole.DATA_QUALITY,
    WorkflowStage.REVIEW: AgentRole.SECURITY,
    WorkflowStage.SHIP: AgentRole.RELEASE,
}


class WorkflowState(BaseModel):
    workflow_id: str = Field(default_factory=lambda: str(uuid4()))
    title: str
    stage: WorkflowStage = WorkflowStage.RECEIVED
    attempt_count: int = 0
    max_attempts: int = 8
    artifacts: dict[str, Any] = Field(default_factory=dict)
    task_history: list[AgentTaskResult] = Field(default_factory=list)
    blocked_reason: str | None = None
    created_at: datetime = Field(default_factory=utc_now)
    updated_at: datetime = Field(default_factory=utc_now)

    def advance(self) -> None:
        if self.stage == WorkflowStage.BLOCKED:
            raise ValidationError("Cannot advance a blocked workflow")
        if self.stage == WorkflowStage.COMPLETED:
            return
        idx = STAGE_ORDER.index(self.stage)
        if idx + 1 >= len(STAGE_ORDER):
            self.stage = WorkflowStage.COMPLETED
        else:
            self.stage = STAGE_ORDER[idx + 1]
        self.updated_at = utc_now()


class Supervisor:
    def __init__(self, state_dir: str | Path = "rebuild/execution_ledger/workflows") -> None:
        self.state_dir = Path(state_dir)
        self.state_dir.mkdir(parents=True, exist_ok=True)

    def start(self, title: str, *, inputs: dict[str, Any] | None = None) -> WorkflowState:
        state = WorkflowState(title=title, artifacts={"inputs": inputs or {}})
        self.save(state)
        return state

    def save(self, state: WorkflowState) -> Path:
        state.updated_at = utc_now()
        path = self.state_dir / f"{state.workflow_id}.json"
        path.write_text(state.model_dump_json(indent=2))
        return path

    def load(self, workflow_id: str) -> WorkflowState:
        path = self.state_dir / f"{workflow_id}.json"
        if not path.exists():
            raise ValidationError(f"workflow not found: {workflow_id}")
        return WorkflowState.model_validate_json(path.read_text())

    def next_task(self, state: WorkflowState) -> AgentTask:
        if state.attempt_count >= state.max_attempts:
            state.stage = WorkflowStage.BLOCKED
            state.blocked_reason = "Attempt limit exceeded (anti-loop)."
            self.save(state)
            raise ValidationError(state.blocked_reason)
        role = STAGE_ROLE.get(state.stage, AgentRole.SUPERVISOR)
        if state.stage == WorkflowStage.RECEIVED:
            state.advance()
            role = STAGE_ROLE[state.stage]
        return AgentTask(
            role=role,
            objective=f"Execute stage `{state.stage.value}` for: {state.title}",
            inputs=state.artifacts.get("inputs", {}),
            required_evidence=[f"stage:{state.stage.value}"],
            tool_permissions=["read", "discover", "validate", "spec", "build"],
        )

    def record_result(self, state: WorkflowState, result: AgentTaskResult) -> WorkflowState:
        problems = result.validate_against_contract()
        if problems:
            state.stage = WorkflowStage.BLOCKED
            state.blocked_reason = "; ".join(problems)
            state.task_history.append(result)
            self.save(state)
            return state
        if result.status != "ok":
            state.attempt_count += 1
            state.task_history.append(result)
            if state.attempt_count >= state.max_attempts:
                state.stage = WorkflowStage.BLOCKED
                state.blocked_reason = "Repeated stage failures."
            self.save(state)
            return state

        state.artifacts[state.stage.value] = result.outputs
        state.task_history.append(result)
        state.attempt_count = 0
        if state.stage == WorkflowStage.SHIP:
            # Production ship still requires policy evaluation.
            policy = evaluate_action(
                actor=result.role.value,
                action="deploy_production",
                target={
                    "workspace": result.outputs.get("workspace", "Foundation"),
                    "name": result.outputs.get("item_name", state.title),
                },
                environment="foundation",
                approval=result.outputs.get("approval"),
            )
            if policy.decision != PolicyDecision.ALLOW:
                state.stage = WorkflowStage.BLOCKED
                state.blocked_reason = "; ".join(policy.reasons)
                self.save(state)
                raise PolicyDeniedError(state.blocked_reason, decision=policy.decision.value)
        state.advance()
        self.save(state)
        return state
