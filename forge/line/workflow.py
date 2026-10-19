"""Persistent workflow state machine with bounded retries."""

from __future__ import annotations

from typing import Any
from uuid import uuid4

from forge.configuration import load_settings
from forge.line.evidence import (
    REQUIRED_REVIEW_FILES as REVIEW_FILE_BY_TYPE,
    TRUST_BOUNDARY,
    VerificationReport,
    verify_approval,
    write_synthetic_demo_bundle,
)
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

DEFAULT_PLATFORM_PROFILE = "forge-default"
REQUIRED_REVIEW_FILES = tuple(REVIEW_FILE_BY_TYPE.values())

_EVIDENCE_GATED_STAGES = frozenset(
    {
        WorkflowStage.APPROVAL_PENDING,
        WorkflowStage.DEPLOYMENT_READY,
    }
)


class InvalidTransitionError(ValueError):
    pass


class EvidenceRequiredError(ValueError):
    """Raised when approval requires proof or reviews that are missing or invalid."""


class WorkflowEngine:
    def __init__(self, store: JobStore | None = None) -> None:
        self.store = store or JobStore()

    def create_job(
        self,
        title: str,
        *,
        autonomy_level: AutonomyLevel = AutonomyLevel.L2_BUILD_TEST_ISOLATED,
        platform_profile: str = DEFAULT_PLATFORM_PROFILE,
        project_id: str | None = None,
        metadata: dict[str, Any] | None = None,
    ) -> JobState:
        meta = dict(metadata or {})
        meta.pop("evidence_mode", None)
        meta.pop("demo_mode", None)
        job = JobState(
            title=title,
            autonomy_level=autonomy_level,
            platform_profile=platform_profile,
            build_id=uuid4().hex[:12],
            demo_mode=False,
            started_at=utc_now(),
            metadata=meta,
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
        if new_stage in _EVIDENCE_GATED_STAGES:
            self.require_approval_evidence(job, production=False)
        if new_stage == WorkflowStage.DEPLOYMENT_READY and not self._has_current_human_approval(job):
            raise InvalidTransitionError("DEPLOYMENT_READY requires a recorded human approval for this build")
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
                "build_id": job.build_id,
                "at": utc_now().isoformat(),
            }
        )
        self.store.save(job)
        return job

    def rework(self, job: JobState, *, note: str, actor: str = "human") -> JobState:
        """Return job to BUILDING and retire the current build's evidence."""
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
                "build_id": job.build_id,
                "at": utc_now().isoformat(),
            }
        )
        job.validation_evidence.append(f"rework: {note}")
        job.build_id = uuid4().hex[:12]
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
        settings = load_settings()
        if deploy_production:
            policy = evaluate_action(
                actor=actor,
                action="deploy_production",
                target={"workspace": settings.prod_workspace, "name": target_name or job.title},
                environment="production",
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
                        "trust_boundary": TRUST_BOUNDARY,
                    }
                )
                self.store.save(job)
                raise PermissionError("; ".join(policy.reasons))
        self.require_approval_evidence(job, production=deploy_production)
        if not authorized:
            job.approval_decisions.append(
                {
                    "status": "rejected",
                    "actor": actor,
                    "at": utc_now().isoformat(),
                    "trust_boundary": TRUST_BOUNDARY,
                }
            )
            return self.transition(job, WorkflowStage.CANCELLED, reason="approval rejected")
        job.approval_decisions.append(
            {
                "status": "approved",
                "actor": actor,
                "build_id": job.build_id,
                "deploy_production": deploy_production,
                "at": utc_now().isoformat(),
                "trust_boundary": TRUST_BOUNDARY,
            }
        )
        return self.transition(job, WorkflowStage.DEPLOYMENT_READY, reason="human approved")

    def verify(self, job: JobState, *, production: bool = False) -> VerificationReport:
        return verify_approval(self.store, job, production=production)

    def require_approval_evidence(self, job: JobState, *, production: bool = False) -> None:
        report = self.verify(job, production=production)
        if not report.ready:
            raise EvidenceRequiredError("; ".join(report.problems))

    def missing_approval_evidence(self, job: JobState, *, production: bool = False) -> list[str]:
        return self.verify(job, production=production).problems

    def attach_demo_evidence(self, job: JobState) -> JobState:
        """Opt this job into demo mode and attach synthetic evidence.

        Synthetic evidence never qualifies a real job. Calling this method is the
        explicit demo switch; create_job cannot turn it on.
        """
        if not job.build_id:
            job.build_id = uuid4().hex[:12]
        job.demo_mode = True
        write_synthetic_demo_bundle(self.store, job)
        if not any(entry.lower().startswith("test:") for entry in job.validation_evidence):
            job.validation_evidence.append("test: synthetic demo evidence (not a real execution)")
        self.store.save(job)
        return job

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
                if stage == WorkflowStage.APPROVAL_PENDING:
                    job = self.attach_demo_evidence(job)
                job = self.transition(job, stage, reason="demo advance")
        return job

    @staticmethod
    def _has_current_human_approval(job: JobState) -> bool:
        for decision in reversed(job.approval_decisions):
            status = decision.get("status")
            if status == "approved" and decision.get("build_id") == job.build_id:
                return True
            if status in {"rework", "rejected", "denied"}:
                return False
        return False
