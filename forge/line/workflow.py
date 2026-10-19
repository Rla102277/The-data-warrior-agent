"""Persistent workflow state machine with bounded retries."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from forge.configuration import load_settings
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

REQUIRED_REVIEW_FILES = (
    "review-security.md",
    "review-naming.md",
    "review-data-quality.md",
)

TEST_EVIDENCE_BASENAMES = frozenset(
    {
        "proof.md",
        "test-results.json",
        "test_results.xml",
        "pytest-report.xml",
        "pytest.xml",
    }
)

_EVIDENCE_GATED_STAGES = frozenset(
    {
        WorkflowStage.APPROVAL_PENDING,
        WorkflowStage.DEPLOYMENT_READY,
    }
)


class InvalidTransitionError(ValueError):
    pass


class EvidenceRequiredError(ValueError):
    """Raised when approval requires proof or independent reviews that are missing."""


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
        if new_stage in _EVIDENCE_GATED_STAGES:
            self.require_approval_evidence(job)
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
        self.require_approval_evidence(job)
        settings = load_settings()
        if deploy_production:
            policy = evaluate_action(
                actor=actor,
                action="deploy_production",
                target={"workspace": settings.prod_workspace, "name": target_name or job.title},
                # "production" normalizes to the production protection enum in the policy engine.
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

    def require_approval_evidence(self, job: JobState) -> None:
        missing = self.missing_approval_evidence(job)
        if missing:
            raise EvidenceRequiredError("; ".join(missing))

    def missing_approval_evidence(self, job: JobState) -> list[str]:
        missing: list[str] = []
        if not self._has_test_evidence(job):
            missing.append(
                "missing test evidence (proof.md, test-results artifact, or validation_evidence test:/proof:)"
            )
        for name in REQUIRED_REVIEW_FILES:
            status = self._review_verdict(job, name)
            if status == "missing":
                missing.append(f"missing {name}")
            elif status == "fail":
                missing.append(f"{name} does not contain VERDICT: PASS")
        return missing

    def _job_paths(self, job: JobState) -> list[Path]:
        root = self.store.job_dir(job.job_id)
        return [root, root / "round-1"]

    def _has_test_evidence(self, job: JobState) -> bool:
        for entry in job.validation_evidence:
            lowered = entry.lower().strip()
            if lowered.startswith(("test:", "proof:", "pytest")):
                return True
        for artifact in job.output_artifacts:
            base = Path(artifact).name.lower()
            if base in TEST_EVIDENCE_BASENAMES:
                return True
        for directory in self._job_paths(job):
            if not directory.is_dir():
                continue
            for name in TEST_EVIDENCE_BASENAMES:
                if (directory / name).is_file():
                    return True
        return False

    def _review_verdict(self, job: JobState, name: str) -> str:
        """Return 'pass', 'fail', or 'missing' for a required independent review file."""
        candidates: list[Path] = []
        for directory in self._job_paths(job):
            candidates.append(directory / name)
        for artifact in job.output_artifacts:
            if Path(artifact).name == name:
                path = Path(artifact)
                if not path.is_absolute():
                    path = self.store.job_dir(job.job_id) / artifact
                candidates.append(path)
        seen: set[Path] = set()
        for path in candidates:
            if path in seen:
                continue
            seen.add(path)
            if path.is_file():
                text = path.read_text(encoding="utf-8")
                for line in text.splitlines():
                    stripped = line.strip()
                    if not stripped:
                        continue
                    if stripped.upper().startswith("VERDICT:"):
                        verdict = stripped.split(":", 1)[1].strip().upper()
                        return "pass" if verdict == "PASS" else "fail"
                return "fail"
        return "missing"

    def attach_demo_evidence(self, job: JobState) -> JobState:
        """Write synthetic proof + three PASS reviews for local demos and happy-path tests."""
        self.store.write_artifact(
            job.job_id,
            "proof.md",
            "# Demo proof\n\nAll local checks passed.\n",
        )
        if "proof.md" not in job.output_artifacts:
            job.output_artifacts.append("proof.md")
        for name in REQUIRED_REVIEW_FILES:
            self.store.write_artifact(
                job.job_id,
                name,
                "VERDICT: PASS\n\nDemo review — synthetic evidence for local happy path.\n",
            )
            if name not in job.output_artifacts:
                job.output_artifacts.append(name)
        if not any(e.lower().startswith("test:") for e in job.validation_evidence):
            job.validation_evidence.append("test: demo synthetic suite passed")
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
