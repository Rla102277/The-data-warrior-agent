from __future__ import annotations

from pathlib import Path

import pytest

from forge.agents import AgentRole, AgentTaskResult, Supervisor
from forge.agents.supervisor import WorkflowStage
from forge.exceptions import PolicyDeniedError, ValidationError


def test_supervisor_advances_and_persists(tmp_path: Path) -> None:
    supervisor = Supervisor(state_dir=tmp_path)
    state = supervisor.start("Add stage ingest for web listings")
    task = supervisor.next_task(state)
    assert task.role == AgentRole.DISCOVERY
    state = supervisor.record_result(
        state,
        AgentTaskResult(
            task_id=task.task_id,
            role=task.role,
            status="ok",
            outputs={"inventory_count": 3},
            evidence=["fixture"],
        ),
    )
    assert state.stage.value == "spec"
    reloaded = supervisor.load(state.workflow_id)
    assert reloaded.stage.value == "spec"
    assert "discover" in reloaded.artifacts


def test_agent_cannot_self_certify_production(tmp_path: Path) -> None:
    supervisor = Supervisor(state_dir=tmp_path)
    state = supervisor.start("Ship something")
    task = supervisor.next_task(state)
    blocked = supervisor.record_result(
        state,
        AgentTaskResult(
            task_id=task.task_id,
            role=task.role,
            status="ok",
            outputs={},
            self_certified_production=True,
        ),
    )
    assert blocked.stage.value == "blocked"
    assert blocked.blocked_reason is not None


def test_ship_without_approval_is_denied(tmp_path: Path) -> None:
    supervisor = Supervisor(state_dir=tmp_path)
    state = supervisor.start("Promote item")
    # Force stage to ship.
    state.stage = WorkflowStage.SHIP
    with pytest.raises(PolicyDeniedError):
        supervisor.record_result(
            state,
            AgentTaskResult(
                task_id="t1",
                role=AgentRole.RELEASE,
                status="ok",
                outputs={"workspace": "Foundation", "item_name": "pipeline_x"},
            ),
        )


def test_attempt_limit_blocks_loops(tmp_path: Path) -> None:
    supervisor = Supervisor(state_dir=tmp_path)
    state = supervisor.start("Loop risk")
    state.max_attempts = 1
    state.attempt_count = 1
    with pytest.raises(ValidationError, match="Attempt limit"):
        supervisor.next_task(state)
