"""Local-orders acceptance for the Forge evidence gate.

Runs negative checks before a real passing test, three structured reviews,
verification, and a stop at human approval. Does not fabricate PASS reviews
or treat synthetic demo evidence as production proof.
"""

from __future__ import annotations

import json
import subprocess
import sys
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from forge.cli.main import main
from forge.line import JobStore, WorkflowEngine, WorkflowStage
from forge.line.evidence import record_review, run_authorized_test


def _cli(args: list[str]) -> int:
    return main(args)


def run(jobs_root: Path | None = None) -> dict[str, Any]:
    jobs_root = jobs_root or (ROOT / "demos" / "local_orders" / "acceptance_jobs")
    if jobs_root.exists():
        for child in jobs_root.glob("*"):
            if child.is_dir():
                for path in sorted(child.rglob("*"), reverse=True):
                    if path.is_file():
                        path.unlink()
                    elif path.is_dir():
                        path.rmdir()
                child.rmdir()
    engine = WorkflowEngine(JobStore(jobs_root))
    job = engine.create_job(
        "local orders evidence acceptance",
        metadata={"demo": "local_orders", "acceptance": True},
    )
    assert job.demo_mode is False
    steps = [
        (WorkflowStage.DISCOVERY, "ground: decision is whether daily sales totals reconcile"),
        (WorkflowStage.REQUIREMENTS, "owner: demo operator; success: order_count 12"),
        (WorkflowStage.SPECIFICATION, "spec: quarantine bad rows; match expected aggregates"),
        (WorkflowStage.ARCHITECTURE, "grain: one analytics row; source: local csv fixtures"),
        (WorkflowStage.PLANNING, "steps: failing proof, implement via existing transform, passing proof, reviews"),
        (WorkflowStage.BUILDING, "implementation is demos/local_orders transform"),
        (WorkflowStage.CODE_VALIDATION, "red test recorded next"),
        (WorkflowStage.DATA_VALIDATION, "duckdb reconciliation lives in the passing command"),
        (WorkflowStage.SECURITY_REVIEW, "local fixtures only"),
        (WorkflowStage.INDEPENDENT_REVIEW, "three review perspectives"),
    ]
    for stage, reason in steps:
        job = engine.transition(job, stage, reason=reason)

    commands: list[dict[str, Any]] = []

    def record_run(name: str, argv: list[str]) -> Any:
        evidence = run_authorized_test(engine.store, job, argv, cwd=ROOT, allow_root=ROOT)
        commands.append(
            {
                "name": name,
                "command": evidence.command,
                "exit_code": evidence.exit_code,
                "synthetic": evidence.synthetic,
                "evidence_id": evidence.evidence_id,
                "build_id": evidence.build_id,
            }
        )
        return evidence

    failed = record_run(name="failing-test", argv=[sys.executable, "-c", "import sys; sys.exit(1)"])
    red = engine.verify(job)
    assert failed.exit_code == 1
    assert red.ready is False
    assert any("latest required test failed" in item for item in red.problems)

    passing_code = (
        "from demos.local_orders.run_demo import transform; "
        "result = transform(); "
        "assert result['analytics']['order_count'] == 12; "
        "assert result['analytics']['gross_revenue'] == 1250.5; "
        "assert result['quarantine_count'] == 2"
    )
    passed = record_run(name="passing-test", argv=[sys.executable, "-c", passing_code])
    assert passed.exit_code == 0
    assert passed.synthetic is False

    engine.store.write_artifact(job.job_id, "review-security.md", "VERDICT: PASS\nprose only\n")
    fake = engine.verify(job)
    assert any("fake PASS text" in item for item in fake.problems)

    record_review(
        engine.store,
        job,
        review_type="security",
        reviewer_id="acceptance-examiner",
        verdict="CHANGES",
        findings=["negative check: changes block approval"],
        evidence_ids=[passed.evidence_id],
    )
    for review_type in ("naming", "data-quality"):
        record_review(
            engine.store,
            job,
            review_type=review_type,
            reviewer_id="acceptance-examiner",
            verdict="PASS",
            findings=[f"{review_type} matches local-orders aggregates"],
            evidence_ids=[passed.evidence_id],
        )
    changes = engine.verify(job)
    assert any("CHANGES" in item for item in changes.problems)

    record_review(
        engine.store,
        job,
        review_type="security",
        reviewer_id="acceptance-examiner",
        verdict="PASS",
        findings=["local fixtures only; no secrets or production credentials"],
        evidence_ids=[passed.evidence_id],
    )
    missing_quality = engine.store.job_dir(job.job_id) / "reviews" / "data-quality.json"
    hidden = missing_quality.read_text(encoding="utf-8")
    missing_quality.unlink()
    missing = engine.verify(job)
    assert any("review-data-quality.md" in item for item in missing.problems)
    missing_quality.write_text(hidden)

    stdout = engine.store.safe_path(job.job_id, passed.stdout_path)
    original = stdout.read_text(encoding="utf-8")
    stdout.write_text(original + "tamper\n")
    tampered = engine.verify(job)
    assert any("tampered" in item for item in tampered.problems)
    stdout.write_text(original)

    ready = engine.verify(job)
    if not ready.ready:
        raise RuntimeError("; ".join(ready.problems))
    job = engine.transition(job, WorkflowStage.APPROVAL_PENDING, reason="human approval pending")

    verify_args = ["job", "verify", "--job-id", job.job_id, "--jobs-dir", str(jobs_root)]
    verify_code = _cli(verify_args)
    commands.append({"name": "forge job verify", "command": ["forge", *verify_args], "exit_code": verify_code})
    assert verify_code == 0

    unauth_args = [
        "job",
        "approve",
        "--job-id",
        job.job_id,
        "--jobs-dir",
        str(jobs_root),
    ]
    unauth_code = _cli(unauth_args)
    commands.append({"name": "forge job approve without --authorized", "command": ["forge", *unauth_args], "exit_code": unauth_code})
    cancelled = engine.resume(job.job_id)
    assert cancelled.stage == WorkflowStage.CANCELLED
    assert unauth_code == 2

    # The unauthorized attempt is the negative approval. Rebuild the same proof
    # and stop at APPROVAL_PENDING so a human still has to authorize deployment.
    job = engine.create_job("local orders evidence acceptance pending")
    for stage, reason in steps:
        job = engine.transition(job, stage, reason=reason)
    final = record_run(name="passing-test-pending", argv=[sys.executable, "-c", passing_code])
    for review_type, finding in (
        ("security", "local fixtures only; no secrets or production credentials"),
        ("naming", "analytics grain is one daily summary row"),
        ("data-quality", "order_count 12, gross_revenue 1250.5, quarantine 2"),
    ):
        record_review(
            engine.store,
            job,
            review_type=review_type,
            reviewer_id="acceptance-examiner",
            verdict="PASS",
            findings=[finding],
            evidence_ids=[final.evidence_id],
        )
    pending_report = engine.verify(job)
    assert pending_report.ready, pending_report.problems
    job = engine.transition(job, WorkflowStage.APPROVAL_PENDING, reason="human approval pending")
    assert job.stage == WorkflowStage.APPROVAL_PENDING
    assert job.demo_mode is False

    summary = {
        "status": "approval_pending",
        "job_id": job.job_id,
        "stage": job.stage.value,
        "build_id": job.build_id,
        "evidence_id": final.evidence_id,
        "synthetic": False,
        "reviews_independent": pending_report.reviews_independent,
        "notes": pending_report.notes,
        "negatives_observed": [
            "failing test blocked verification",
            "fake VERDICT: PASS markdown blocked verification",
            "CHANGES security review blocked verification",
            "missing data-quality review blocked verification",
            "tampered stdout blocked verification",
            "approve without --authorized cancelled the job and did not reach DEPLOYMENT_READY",
        ],
        "commands": commands,
        "trust_boundary": (
            "--authorized is an operator attestation on this host, not cryptographic identity. "
            "This run stopped at APPROVAL_PENDING for the successful job."
        ),
    }
    report_path = jobs_root.parent / "acceptance-report.json"
    report_path.write_text(json.dumps(summary, indent=2))
    return summary


if __name__ == "__main__":
    outcome = run()
    print(json.dumps(outcome, indent=2))
    raise SystemExit(0 if outcome["status"] == "approval_pending" else 1)
