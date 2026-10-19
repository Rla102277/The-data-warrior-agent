"""Adversarial checks for Forge test evidence and build-bound reviews."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

from forge.cli.main import main
from forge.line import EvidenceRequiredError, InvalidTransitionError, JobStore, WorkflowEngine, WorkflowStage
from forge.line.evidence import (
    TestEvidence,
    record_review,
    run_authorized_test,
    save_evidence,
    write_synthetic_demo_bundle,
)
from forge.line.models import utc_now


def _advance(engine: WorkflowEngine, title: str):
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


def _run(engine: WorkflowEngine, job, cwd: Path, code: str):
    script = cwd / f"check_{job.build_id}_{code}.py"
    script.write_text(code + "\n")
    return run_authorized_test(
        engine.store,
        job,
        [sys.executable, str(script)],
        cwd=cwd,
        allow_root=cwd,
    )


def _reviews(engine: WorkflowEngine, job, evidence_id: str, *, verdict: str = "PASS", skip: str | None = None, reviewer: str = "examiner") -> None:
    for review_type in ("security", "naming", "data-quality"):
        if review_type == skip:
            continue
        record_review(
            engine.store,
            job,
            review_type=review_type,
            reviewer_id=reviewer,
            verdict=verdict if review_type == "security" or verdict == "PASS" else "PASS",
            findings=[f"{review_type} checked against {evidence_id}"],
            evidence_ids=[evidence_id],
            provenance="same-agent-perspective",
        )


def _ready_job(engine: WorkflowEngine, tmp_path: Path, title: str = "real job"):
    job = _advance(engine, title)
    evidence = _run(engine, job, tmp_path, "print('ok')")
    assert evidence.exit_code == 0
    assert evidence.synthetic is False
    _reviews(engine, job, evidence.evidence_id)
    return job, evidence


def test_real_pass_and_three_reviews_can_be_approved(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job, evidence = _ready_job(engine, tmp_path)
    report = engine.verify(job)
    assert report.ready, report.problems
    assert report.reviews_independent is False
    assert any("not recorded as three independently executed reviewers" in note for note in report.notes)
    job = engine.transition(job, WorkflowStage.APPROVAL_PENDING, reason="evidence ready")
    job = engine.approve(job, actor="human", authorized=True, deploy_production=False)
    assert job.stage == WorkflowStage.DEPLOYMENT_READY
    assert evidence.command[0] == sys.executable


def test_missing_test_execution(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance(engine, "no test")
    report = engine.verify(job)
    assert any("no real test execution" in item for item in report.problems)


def test_failed_test_execution(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance(engine, "red")
    evidence = _run(engine, job, tmp_path, "import sys; sys.exit(1)")
    assert evidence.exit_code == 1
    assert evidence.status.value == "failed"
    _reviews(engine, job, evidence.evidence_id)
    report = engine.verify(job)
    assert any("latest required test failed" in item for item in report.problems)


def test_missing_stdout_evidence(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job, evidence = _ready_job(engine, tmp_path, "missing stdout")
    engine.store.safe_path(job.job_id, evidence.stdout_path).unlink()
    report = engine.verify(job)
    assert any("missing stdout/stderr evidence" in item for item in report.problems)


def test_tampered_test_artifact(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job, evidence = _ready_job(engine, tmp_path, "tamper")
    path = engine.store.safe_path(job.job_id, evidence.stdout_path)
    path.write_text("tampered\n")
    report = engine.verify(job)
    assert any("tampered test artifact" in item for item in report.problems)


def test_cross_job_evidence_reuse(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job, evidence = _ready_job(engine, tmp_path, "owner")
    other = engine.create_job("thief")
    stolen = evidence.model_copy(update={"job_id": other.job_id})
    payload_path = engine.store.job_dir(job.job_id) / "evidence" / evidence.evidence_id / "record.json"
    payload_path.write_text(stolen.model_dump_json(indent=2))
    report = engine.verify(job)
    assert any("another job" in item for item in report.problems)


def test_stale_review_after_rework(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job, _evidence = _ready_job(engine, tmp_path, "stale")
    job = engine.transition(job, WorkflowStage.APPROVAL_PENDING, reason="hold")
    old_build = job.build_id
    job = engine.rework(job, note="change the build", actor="human")
    assert job.build_id != old_build
    assert job.stage == WorkflowStage.BUILDING
    report = engine.verify(job)
    assert any("earlier build" in item or "stale review" in item for item in report.problems)
    job = engine.transition(job, WorkflowStage.CODE_VALIDATION)
    for stage in (
        WorkflowStage.DATA_VALIDATION,
        WorkflowStage.SECURITY_REVIEW,
        WorkflowStage.INDEPENDENT_REVIEW,
    ):
        job = engine.transition(job, stage)
    with pytest.raises(EvidenceRequiredError, match="earlier build|stale review|no real test execution"):
        engine.transition(job, WorkflowStage.APPROVAL_PENDING)


def test_failed_security_review(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance(engine, "security fail")
    evidence = _run(engine, job, tmp_path, "print('ok')")
    record_review(
        engine.store,
        job,
        review_type="security",
        reviewer_id="guardian",
        verdict="CHANGES",
        findings=["secret in sample"],
        evidence_ids=[evidence.evidence_id],
    )
    _reviews(engine, job, evidence.evidence_id, skip="security")
    report = engine.verify(job)
    assert any("CHANGES" in item and "review-security.md" in item for item in report.problems)


def test_missing_data_quality_review(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance(engine, "missing dq")
    evidence = _run(engine, job, tmp_path, "print('ok')")
    _reviews(engine, job, evidence.evidence_id, skip="data-quality")
    report = engine.verify(job)
    assert any("review-data-quality.md" in item for item in report.problems)


def test_fake_pass_text_without_structured_evidence(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job, _evidence = _ready_job(engine, tmp_path, "fake pass")
    (engine.store.job_dir(job.job_id) / "reviews" / "security.json").unlink()
    engine.store.write_artifact(job.job_id, "review-security.md", "VERDICT: PASS\nlooks fine\n")
    report = engine.verify(job)
    assert any("fake PASS text" in item for item in report.problems)


def test_synthetic_demo_evidence_rejected_on_real_job(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance(engine, "real")
    assert job.demo_mode is False
    write_synthetic_demo_bundle(engine.store, job)
    report = engine.verify(job)
    assert report.ready is False
    assert any("synthetic demo evidence" in item for item in report.problems)
    job.stage = WorkflowStage.APPROVAL_PENDING
    engine.store.save(job)
    with pytest.raises(EvidenceRequiredError, match="synthetic"):
        engine.approve(job, actor="human", authorized=True, deploy_production=False)


def test_approval_without_authorization(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job, _evidence = _ready_job(engine, tmp_path, "unauth")
    job = engine.transition(job, WorkflowStage.APPROVAL_PENDING, reason="wait")
    job = engine.approve(job, actor="human", authorized=False, deploy_production=False)
    assert job.stage == WorkflowStage.CANCELLED
    assert job.stage != WorkflowStage.DEPLOYMENT_READY


def test_direct_transition_cannot_skip_human_approval(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job, _evidence = _ready_job(engine, tmp_path, "bypass")
    job = engine.transition(job, WorkflowStage.APPROVAL_PENDING, reason="wait")
    with pytest.raises(InvalidTransitionError, match="human approval"):
        engine.transition(job, WorkflowStage.DEPLOYMENT_READY)


def test_resume_across_process_restart(tmp_path: Path) -> None:
    root = tmp_path / "jobs"
    engine = WorkflowEngine(JobStore(root))
    job, evidence = _ready_job(engine, tmp_path, "resume")
    job_id = job.job_id
    restarted = WorkflowEngine(JobStore(root))
    loaded = restarted.resume(job_id)
    report = restarted.verify(loaded)
    assert report.ready
    assert report.evidence_id == evidence.evidence_id


def test_cli_verify_exit_codes(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance(engine, "cli")
    assert main(["job", "verify", "--job-id", job.job_id, "--jobs-dir", str(tmp_path / "jobs")]) == 1
    evidence = _run(engine, job, tmp_path, "print('ok')")
    _reviews(engine, job, evidence.evidence_id)
    assert main(["job", "verify", "--job-id", job.job_id, "--jobs-dir", str(tmp_path / "jobs")]) == 0
    code = main(
        [
            "job",
            "test",
            "--job-id",
            job.job_id,
            "--jobs-dir",
            str(tmp_path / "jobs"),
            "--",
            sys.executable,
            "-c",
            "import sys; sys.exit(3)",
        ]
    )
    assert code == 3
    outside = main(
        [
            "job",
            "test",
            "--job-id",
            job.job_id,
            "--jobs-dir",
            str(tmp_path / "jobs"),
            "--cwd",
            str(tmp_path),
            "--",
            sys.executable,
            "-c",
            "print('nope')",
        ]
    )
    assert outside == 2


def test_path_traversal_and_external_artifact(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job, evidence = _ready_job(engine, tmp_path, "paths")
    record_path = engine.store.job_dir(job.job_id) / "evidence" / evidence.evidence_id / "record.json"
    payload = json.loads(record_path.read_text())
    payload["artifact_hashes"]["../../etc/passwd"] = "abc"
    payload["artifact_hashes"]["/tmp/outside.txt"] = "def"
    record_path.write_text(json.dumps(payload))
    report = engine.verify(job)
    assert any("path traversal" in item for item in report.problems)
    assert any("external artifact reference" in item for item in report.problems)
    with pytest.raises(ValueError, match="outside job directory"):
        engine.store.write_artifact(job.job_id, "../escape.txt", "nope")


def test_job_metadata_cannot_launch_a_test(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = engine.create_job("meta", metadata={"test_command": "echo should-not-run"})
    assert job.metadata.get("test_command") == "echo should-not-run"
    assert job.demo_mode is False
    report = engine.verify(job)
    assert report.ready is False
    assert list((engine.store.job_dir(job.job_id) / "evidence").glob("*")) == []


def test_create_job_ignores_demo_mode_metadata(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = engine.create_job("sneak", metadata={"demo_mode": True, "evidence_mode": "demo"})
    assert job.demo_mode is False
    assert "demo_mode" not in job.metadata


def test_recorded_command_is_not_inferred(tmp_path: Path) -> None:
    engine = WorkflowEngine(JobStore(tmp_path / "jobs"))
    job = _advance(engine, "literal")
    evidence = run_authorized_test(
        engine.store,
        job,
        [sys.executable, "-c", "print('PASS')\nimport sys\nsys.exit(2)"],
        cwd=tmp_path,
        allow_root=tmp_path,
    )
    assert "PASS" in engine.store.safe_path(job.job_id, evidence.stdout_path).read_text()
    assert evidence.exit_code == 2
    assert evidence.status.value == "failed"


def test_manual_evidence_model_round_trip(tmp_path: Path) -> None:
    now = utc_now()
    record = TestEvidence(
        job_id="job",
        build_id="build",
        command=["python", "-c", "print(1)"],
        cwd=str(tmp_path),
        started_at=now,
        finished_at=now,
        exit_code=0,
        stdout_path="evidence/x/stdout.txt",
        stderr_path="evidence/x/stderr.txt",
        artifact_hashes={"evidence/x/stdout.txt": "abc"},
        status="passed",
        synthetic=False,
        source_commit=None,
    )
    store = JobStore(tmp_path / "jobs")
    job = WorkflowEngine(store).create_job("holder")
    record.job_id = job.job_id
    record.build_id = job.build_id
    store.write_artifact(job.job_id, record.stdout_path, "1\n")
    store.write_artifact(job.job_id, record.stderr_path, "")
    save_evidence(store, record)
    loaded = json.loads((store.job_dir(job.job_id) / "evidence" / record.evidence_id / "record.json").read_text())
    assert loaded["command"] == ["python", "-c", "print(1)"]
    assert loaded["synthetic"] is False
    assert "evidence_id" in loaded
