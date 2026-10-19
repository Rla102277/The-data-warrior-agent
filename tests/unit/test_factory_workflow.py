"""Forge Line workflow persistence and transition tests."""

from __future__ import annotations

import pytest

from forge.line import EvidenceRequiredError, InvalidTransitionError, JobStore, WorkflowEngine, WorkflowStage
from forge.line.models import AgentMessage, AutonomyLevel
from forge.line.workflow import DEFAULT_PLATFORM_PROFILE, REQUIRED_REVIEW_FILES


def _advance_to_independent_review(engine: WorkflowEngine, title: str):
    job = engine.create_job(title)
    for stage in [
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
    ]:
        job = engine.transition(job, stage)
    return job


def test_job_persists_across_store_instances(tmp_path) -> None:
    store = JobStore(tmp_path / "jobs")
    engine = WorkflowEngine(store)
    job = engine.create_job("demo job")
    job_id = job.job_id
    engine.transition(job, WorkflowStage.DISCOVERY, reason="start discovery")

    resumed = WorkflowEngine(JobStore(tmp_path / "jobs")).resume(job_id)
    assert resumed.stage == WorkflowStage.DISCOVERY
    assert resumed.title == "demo job"
    assert resumed.autonomy_level == AutonomyLevel.L2_BUILD_TEST_ISOLATED
    assert resumed.platform_profile == DEFAULT_PLATFORM_PROFILE


def test_default_platform_profile_is_forge_neutral(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = engine.create_job("neutral")
    assert job.platform_profile == "forge-default"
    assert job.platform_profile != "fabric-first-foundation"


def test_invalid_transition_rejected(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = engine.create_job("bad transition")
    with pytest.raises(InvalidTransitionError):
        engine.transition(job, WorkflowStage.DEPLOYING)


def test_repair_rounds_bounded(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = engine.create_job("repair")
    for stage in [
        WorkflowStage.DISCOVERY,
        WorkflowStage.REQUIREMENTS,
        WorkflowStage.SPECIFICATION,
        WorkflowStage.ARCHITECTURE,
        WorkflowStage.PLANNING,
        WorkflowStage.BUILDING,
        WorkflowStage.CODE_VALIDATION,
    ]:
        job = engine.transition(job, stage)
    # First repair
    job = engine.transition(job, WorkflowStage.BUILDING)
    assert job.repair_rounds == 1
    job = engine.transition(job, WorkflowStage.CODE_VALIDATION)
    # Second repair
    job = engine.transition(job, WorkflowStage.BUILDING)
    assert job.repair_rounds == 2
    job = engine.transition(job, WorkflowStage.CODE_VALIDATION)
    # Third repair exhausts
    job = engine.transition(job, WorkflowStage.BUILDING)
    assert job.stage == WorkflowStage.FAILED


def test_production_approve_denied_without_auth(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = engine.create_job("prod gate")
    job = engine.advance_happy_path(job)
    assert job.stage == WorkflowStage.APPROVAL_PENDING
    with pytest.raises(PermissionError):
        engine.approve(
            job,
            actor="tester",
            authorized=False,
            deploy_production=True,
            target_name="pipeline_demo",
        )


def test_rework_from_approval_pending(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = engine.create_job("rework job")
    job = engine.advance_happy_path(job)
    assert job.stage == WorkflowStage.APPROVAL_PENDING
    job = engine.rework(job, note="fix naming", actor="reviewer")
    assert job.stage == WorkflowStage.BUILDING
    assert any("fix naming" in e for e in job.validation_evidence)


def test_approve_to_deployment_ready(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = engine.create_job("approve job")
    job = engine.advance_happy_path(job)
    job = engine.approve(job, actor="human", authorized=True, deploy_production=False)
    assert job.stage == WorkflowStage.DEPLOYMENT_READY


def test_transition_to_approval_pending_rejects_without_evidence(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance_to_independent_review(engine, "no evidence")
    with pytest.raises(EvidenceRequiredError, match="missing test evidence"):
        engine.transition(job, WorkflowStage.APPROVAL_PENDING)


def test_approve_rejects_without_test_evidence(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance_to_independent_review(engine, "approve without tests")
    # Bypass transition gate by forcing stage (simulates tampered / incomplete job state).
    job.stage = WorkflowStage.APPROVAL_PENDING
    engine.store.save(job)
    with pytest.raises(EvidenceRequiredError, match="missing test evidence"):
        engine.approve(job, actor="human", authorized=True, deploy_production=False)


def test_approve_rejects_when_review_missing(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance_to_independent_review(engine, "missing review")
    engine.store.write_artifact(job.job_id, "proof.md", "# proof\n")
    job.output_artifacts.append("proof.md")
    job.validation_evidence.append("test: unit suite passed")
    # Only two of three required reviews.
    for name in REQUIRED_REVIEW_FILES[:2]:
        engine.store.write_artifact(job.job_id, name, "VERDICT: PASS\n")
        job.output_artifacts.append(name)
    job.stage = WorkflowStage.APPROVAL_PENDING
    engine.store.save(job)
    with pytest.raises(EvidenceRequiredError, match="review-data-quality.md"):
        engine.approve(job, actor="human", authorized=True, deploy_production=False)


def test_approve_rejects_when_review_not_pass(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance_to_independent_review(engine, "failing review")
    engine.store.write_artifact(job.job_id, "proof.md", "# proof\n")
    job.output_artifacts.append("proof.md")
    job.validation_evidence.append("test: unit suite passed")
    for name in REQUIRED_REVIEW_FILES:
        verdict = "VERDICT: FAIL\nneeds work\n" if name == "review-security.md" else "VERDICT: PASS\n"
        engine.store.write_artifact(job.job_id, name, verdict)
        job.output_artifacts.append(name)
    job.stage = WorkflowStage.APPROVAL_PENDING
    engine.store.save(job)
    with pytest.raises(EvidenceRequiredError, match="review-security.md"):
        engine.approve(job, actor="human", authorized=True, deploy_production=False)


def test_agent_message_recorded(tmp_path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = engine.create_job("msg")
    msg = AgentMessage(
        job_id=job.job_id,
        project_id=job.project_id,
        agent_id="spec-writer",
        stage=job.stage.value,
        output_artifacts=["spec.md"],
        findings=["captured requirements"],
    )
    job = engine.record_message(job, msg)
    assert len(job.messages) == 1
    assert "spec.md" in job.output_artifacts
