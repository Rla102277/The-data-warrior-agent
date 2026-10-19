"""Persistent workflow state machine with bounded retries."""

from __future__ import annotations

from typing import Any

from forge.line.models import (
    ALLOWED_TRANSITIONS,
    AgentMessage,
    AutonomyLevel,
    JobState,
    WorkflowStage,
    utc_now,
)
from forge.line.store import JobStore
from forge.policies import PolicyDecision, evaluate_action


class InvalidTransitionError(ValueError):
    pass


class WorkflowEngine:
    def __init__(self, store: JobStore | None = None) -> None:
        self.store = store or JobStore()

    def create_job(
        self,
        title: str,
        *,
        autonomy_level: AutonomyLevel = AutonomyLevel.L2_BUILD_TEST_ISOLATED,
        platform_profile: str = "fabric-first-foundation",
        project_id: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> JobState:
        job = JobState(
            title=title,
            autonomy_level=autonomy_level,
            platform_profile=platform_profile,
            started_at=utc_now(),
            metadata=metadata or {},
        )
        if project_id:
            job.project_id = project_id
        job.branch = f"factory/{job.job_id[:8]}"
        self.store.save(job)
        return job

    def transition(self, job: JobState, new_stage: WorkflowStage, *, reason: str = "") -> JobState:
        allowed = ALLOWED_TRANSITIONS.get(job.stage, set())
        if new_stage not in allowed:
            raise InvalidTransitionError(f"Cannot transition {job.stage.value} -> {new_stage.value}")
        if new_stage == WorkflowStage.BUILDING and job.stage in {
            WorkflowStage.CODE_VALIDATION,
            WorkflowStage.DATA_VALIDATION,
            WorkflowStage.SECURITY_REVIEW,
            WorkflowStage.INDEPENDENT_REVIEW,
            WorkflowStage.APPROVAL_PENDING,
        }:
            job.repair_rounds += 1
            if job.repair_rounds > job.max_repair_rounds:
                job.stage = WorkflowStage.FAILED
                job.error_details.append("Repair rounds exhausted")
                job.ended_at = utc_now()
                self.store.save(job)
                return job
        job.stage = new_stage
        job.attempt_count += 1 if new_stage == WorkflowStage.BUILDING else 0
        if reason:
            job.validation_evidence.append(f"{new_stage.value}: {reason}")
        if new_stage in {WorkflowStage.COMPLETED, WorkflowStage.FAILED, WorkflowStage.CANCELLED}:
            job.ended_at = utc_now()
        self.store.save(job)
        return job

    def resume(self, job_id: str) -> JobState:
        """Load job; no stage change. Confirms persistence across restarts."""
        return self.store.load(job_id)

    def cancel(self, job: JobState, *, reason: str = "cancelled") -> JobState:
        if job.stage in {WorkflowStage.COMPLETED, WorkflowStage.CANCELLED}:
            raise InvalidTransitionError(f"Cannot cancel job in {job.stage.value}")
        job.stage = WorkflowStage.CANCELLED
        job.error_details.append(reason)
        job.ended_at = utc_now()
        self.store.save(job)
        return job

    def record_message(self, job: JobState, message: AgentMessage) -> JobState:
        job.messages.append(message)
        for artifact in message.output_artifacts:
            if artifact not in job.output_artifacts:
                job.output_artifacts.append(artifact)
        self.store.save(job)
        return job

    def request_approval(self, job: JobState, *, actor: str, summary: str) -> JobState:
        if job.autonomy_level.value >= AutonomyLevel.L5_NARROW_PROD.value:
            # Still require policy for production
            pass
        job = self.transition(job, WorkflowStage.APPROVAL_PENDING, reason=summary)
        job.approval_decisions.append(
            {
                "status": "pending",
                "actor": actor,
                "summary": summary,
                "at": utc_now().isoformat(),
            }
        )
        self.store.save(job)
        return job

    def rework(self, job: JobState, *, note: str, actor: str = "human") -> JobState:
        """Return job to BUILDING with feedback (bounded by max_repair_rounds)."""
        if job.stage not in {
            WorkflowStage.APPROVAL_PENDING,
            WorkflowStage.CODE_VALIDATION,
            WorkflowStage.DATA_VALIDATION,
            WorkflowStage.INDEPENDENT_REVIEW,
            WorkflowStage.SECURITY_REVIEW,
        }:
            raise InvalidTransitionError(f"rework not allowed from {job.stage.value}")
        job.approval_decisions.append(
            {
                "status": "rework",
                "actor": actor,
                "note": note,
                "at": utc_now().isoformat(),
            }
        )
        job.validation_evidence.append(f"rework: {note}")
        return self.transition(job, WorkflowStage.BUILDING, reason=note)

    def approve(
        self,
        job: JobState,
        *,
        actor: str,
        authorized: bool,
        target_name: str = "",
        deploy_production: bool = False,
    ) -> JobState:
        if job.stage != WorkflowStage.APPROVAL_PENDING:
            raise InvalidTransitionError("approve requires APPROVAL_PENDING")
        if deploy_production:
            policy = evaluate_action(
                actor=actor,
                action="deploy_production",
                target={"workspace": "Foundation", "name": target_name or job.title},
                environment="foundation",
                approval={
                    "authorized": authorized,
                    "item": target_name or job.title,
                    "action": "deploy_production",
                    "explicit_written_authorization": authorized,
                },
            )
            if policy.decision != PolicyDecision.ALLOW:
                job.approval_decisions.append(
                    {
                        "status": "denied",
                        "actor": actor,
                        "reasons": policy.reasons,
                        "at": utc_now().isoformat(),
                    }
                )
                self.store.save(job)
                raise PermissionError("; ".join(policy.reasons))
        if not authorized:
            job.approval_decisions.append(
                {
                    "status": "rejected",
                    "actor": actor,
                    "at": utc_now().isoformat(),
                }
            )
            return self.transition(job, WorkflowStage.CANCELLED, reason="approval rejected")
        job.approval_decisions.append(
            {
                "status": "approved",
                "actor": actor,
                "deploy_production": deploy_production,
                "at": utc_now().isoformat(),
            }
        )
        return self.transition(job, WorkflowStage.DEPLOYMENT_READY, reason="human approved")

    def advance_happy_path(self, job: JobState, *, stop_before: WorkflowStage | None = None) -> JobState:
        """Advance through expected stages for local demos (Level 2)."""
        path = [
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
        ]
        for stage in path:
            if stop_before and stage == stop_before:
                break
            if job.stage == WorkflowStage.RECEIVED or stage in ALLOWED_TRANSITIONS.get(job.stage, set()):
                job = self.transition(job, stage, reason="demo advance")
        return job
