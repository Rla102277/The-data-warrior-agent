"""Job-scoped test evidence and build-bound reviews.

A passing prose note is not a passing test. Approval reads recorded executions
and structured reviews whose artifact hashes still match the files on disk.

Trust boundary: ``forge job approve --authorized`` is an operator attestation on
this host. It is not cryptographic proof of identity. Production execution still
depends on the OS user, repository permissions, and platform policy.
"""

from __future__ import annotations

import hashlib
import json
import subprocess
from datetime import datetime, timezone
from enum import Enum
from pathlib import Path
from typing import Any, ClassVar
from uuid import uuid4

from pydantic import BaseModel, Field

from forge.line.models import JobState, utc_now
from forge.line.store import JobStore

TRUST_BOUNDARY = (
    "forge job approve --authorized is an explicit operator attestation on this host. "
    "It is not cryptographic proof of identity. Production execution still depends on "
    "the OS user, repository permissions, and platform authorization."
)

REQUIRED_REVIEW_FILES = {
    "security": "review-security.md",
    "naming": "review-naming.md",
    "data-quality": "review-data-quality.md",
}


class EvidenceStatus(str, Enum):
    PASSED = "passed"
    FAILED = "failed"
    ERROR = "error"


class ReviewVerdict(str, Enum):
    PASS = "PASS"
    CHANGES = "CHANGES"


class ReviewProvenance(str, Enum):
    INDEPENDENT = "independent"
    SAME_AGENT = "same-agent-perspective"
    DEMO = "demo"


class TestEvidence(BaseModel):
    __test__: ClassVar[bool] = False
    evidence_id: str = Field(default_factory=lambda: str(uuid4()))
    job_id: str
    build_id: str
    command: list[str]
    cwd: str
    started_at: datetime
    finished_at: datetime
    exit_code: int
    stdout_path: str
    stderr_path: str
    artifact_hashes: dict[str, str]
    status: EvidenceStatus
    synthetic: bool = False
    source_commit: str | None = None
    repair_rounds: int = 0


class ReviewRecord(BaseModel):
    review_type: str
    job_id: str
    build_id: str
    reviewer_id: str
    verdict: ReviewVerdict
    findings: list[str]
    timestamp: datetime = Field(default_factory=utc_now)
    evidence_ids: list[str]
    content_hash: str = ""
    synthetic: bool = False
    provenance: ReviewProvenance = ReviewProvenance.SAME_AGENT
    repair_rounds: int = 0


class VerificationReport(BaseModel):
    ready: bool
    problems: list[str] = Field(default_factory=list)
    notes: list[str] = Field(default_factory=list)
    build_id: str = ""
    evidence_id: str | None = None
    reviews_independent: bool = False
    synthetic_only: bool = False


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_text(text: str) -> str:
    return sha256_bytes(text.encode("utf-8"))


def _canonical(payload: dict[str, Any]) -> str:
    return json.dumps(payload, sort_keys=True, separators=(",", ":"), default=str)


def review_content_hash(record: ReviewRecord) -> str:
    payload = record.model_dump(mode="json", exclude={"content_hash"})
    return sha256_text(_canonical(payload))


def _path_problem(relative: str) -> str | None:
    rel = Path(relative)
    if rel.is_absolute():
        return f"external artifact reference: {relative}"
    if ".." in rel.parts:
        return f"path traversal: {relative}"
    return None


def evidence_record_path(store: JobStore, job_id: str, evidence_id: str) -> Path:
    return store.safe_path(job_id, f"evidence/{evidence_id}/record.json")


def save_evidence(store: JobStore, record: TestEvidence) -> Path:
    for relative in (record.stdout_path, record.stderr_path, *record.artifact_hashes):
        problem = _path_problem(relative)
        if problem:
            raise ValueError(problem)
    path = evidence_record_path(store, record.job_id, record.evidence_id)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(record.model_dump_json(indent=2))
    return path


def load_evidence(store: JobStore, job_id: str) -> list[TestEvidence]:
    root = store.job_dir(job_id) / "evidence"
    records: list[TestEvidence] = []
    if not root.is_dir():
        return records
    for path in sorted(root.glob("*/record.json")):
        records.append(TestEvidence.model_validate_json(path.read_text(encoding="utf-8")))
    return records


def review_json_path(store: JobStore, job_id: str, review_type: str) -> Path:
    return store.safe_path(job_id, f"reviews/{review_type}.json")


def save_review(store: JobStore, record: ReviewRecord) -> Path:
    if record.review_type not in REQUIRED_REVIEW_FILES:
        raise ValueError(f"unknown review type: {record.review_type}")
    path = review_json_path(store, record.job_id, record.review_type)
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = record.model_dump(mode="json", exclude={"content_hash"})
    record.content_hash = sha256_text(_canonical(payload))
    payload["content_hash"] = record.content_hash
    path.write_text(json.dumps(payload, indent=2))
    filename = REQUIRED_REVIEW_FILES[record.review_type]
    body = "\n".join(
        [
            f"VERDICT: {record.verdict.value}",
            f"reviewer: {record.reviewer_id}",
            f"build: {record.build_id}",
            f"provenance: {record.provenance.value}",
            f"evidence: {', '.join(record.evidence_ids)}",
            "",
            *record.findings,
            "",
        ]
    )
    store.write_artifact(record.job_id, filename, body)
    return path


def load_review(store: JobStore, job_id: str, review_type: str) -> ReviewRecord | None:
    path = store.job_dir(job_id) / "reviews" / f"{review_type}.json"
    if not path.is_file():
        return None
    return ReviewRecord.model_validate_json(path.read_text(encoding="utf-8"))


def _git_head(cwd: Path) -> str | None:
    try:
        proc = subprocess.run(
            ["git", "rev-parse", "HEAD"],
            cwd=cwd,
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
    except (OSError, subprocess.TimeoutExpired):
        return None
    if proc.returncode != 0:
        return None
    sha = proc.stdout.strip()
    return sha or None


def assert_allowed_cwd(cwd: Path, allow_root: Path) -> Path:
    resolved = cwd.resolve()
    root = allow_root.resolve()
    if not resolved.is_dir():
        raise ValueError(f"working directory does not exist: {cwd}")
    if resolved != root and not resolved.is_relative_to(root):
        raise ValueError(f"working directory is outside the allowed root: {resolved}")
    return resolved


def run_authorized_test(
    store: JobStore,
    job: JobState,
    argv: list[str],
    *,
    cwd: Path,
    allow_root: Path,
    timeout_seconds: int = 120,
) -> TestEvidence:
    """Run an explicit argument array. Never reads a command from job metadata."""
    if not argv or any(not isinstance(part, str) or part == "" for part in argv):
        raise ValueError("test command must be an explicit non-empty argument array")
    if not job.build_id:
        raise ValueError("job has no build_id")
    resolved = assert_allowed_cwd(cwd, allow_root)
    started = datetime.now(timezone.utc)
    try:
        proc = subprocess.run(
            argv,
            cwd=resolved,
            capture_output=True,
            text=True,
            timeout=timeout_seconds,
            check=False,
            shell=False,
        )
        exit_code = int(proc.returncode)
        stdout = proc.stdout or ""
        stderr = proc.stderr or ""
        status = EvidenceStatus.PASSED if exit_code == 0 else EvidenceStatus.FAILED
    except subprocess.TimeoutExpired as exc:
        exit_code = 124
        stdout = exc.stdout.decode("utf-8", errors="replace") if isinstance(exc.stdout, bytes) else (exc.stdout or "")
        stderr = exc.stderr.decode("utf-8", errors="replace") if isinstance(exc.stderr, bytes) else (exc.stderr or "")
        stderr = (stderr + "\ntimeout\n").strip() + "\n"
        status = EvidenceStatus.ERROR
    except OSError as exc:
        exit_code = 127
        stdout = ""
        stderr = f"{exc}\n"
        status = EvidenceStatus.ERROR
    finished = datetime.now(timezone.utc)
    evidence_id = str(uuid4())
    stdout_rel = f"evidence/{evidence_id}/stdout.txt"
    stderr_rel = f"evidence/{evidence_id}/stderr.txt"
    store.write_artifact(job.job_id, stdout_rel, stdout)
    store.write_artifact(job.job_id, stderr_rel, stderr)
    hashes = {
        stdout_rel: sha256_text(stdout),
        stderr_rel: sha256_text(stderr),
    }
    record = TestEvidence(
        evidence_id=evidence_id,
        job_id=job.job_id,
        build_id=job.build_id,
        command=list(argv),
        cwd=str(resolved),
        started_at=started,
        finished_at=finished,
        exit_code=exit_code,
        stdout_path=stdout_rel,
        stderr_path=stderr_rel,
        artifact_hashes=hashes,
        status=status,
        synthetic=False,
        source_commit=_git_head(resolved),
        repair_rounds=job.repair_rounds,
    )
    save_evidence(store, record)
    return record


def record_review(
    store: JobStore,
    job: JobState,
    *,
    review_type: str,
    reviewer_id: str,
    verdict: ReviewVerdict | str,
    findings: list[str],
    evidence_ids: list[str],
    provenance: ReviewProvenance | str = ReviewProvenance.SAME_AGENT,
    synthetic: bool = False,
) -> ReviewRecord:
    if not reviewer_id.strip():
        raise ValueError("reviewer identity is required")
    if not findings:
        raise ValueError("review findings are required")
    record = ReviewRecord(
        review_type=review_type,
        job_id=job.job_id,
        build_id=job.build_id,
        reviewer_id=reviewer_id.strip(),
        verdict=ReviewVerdict(verdict),
        findings=findings,
        evidence_ids=list(evidence_ids),
        synthetic=synthetic,
        provenance=ReviewProvenance(provenance),
        repair_rounds=job.repair_rounds,
    )
    save_review(store, record)
    return record


def write_synthetic_demo_bundle(store: JobStore, job: JobState) -> TestEvidence:
    """Mark and persist synthetic evidence. Never counts as a real execution."""
    evidence_id = str(uuid4())
    stdout_rel = f"evidence/{evidence_id}/stdout.txt"
    stderr_rel = f"evidence/{evidence_id}/stderr.txt"
    stdout = "synthetic demo evidence\n"
    stderr = ""
    store.write_artifact(job.job_id, stdout_rel, stdout)
    store.write_artifact(job.job_id, stderr_rel, stderr)
    now = utc_now()
    record = TestEvidence(
        evidence_id=evidence_id,
        job_id=job.job_id,
        build_id=job.build_id,
        command=["forge", "job", "demo"],
        cwd=str(store.job_dir(job.job_id).resolve()),
        started_at=now,
        finished_at=now,
        exit_code=0,
        stdout_path=stdout_rel,
        stderr_path=stderr_rel,
        artifact_hashes={stdout_rel: sha256_text(stdout), stderr_rel: sha256_text(stderr)},
        status=EvidenceStatus.PASSED,
        synthetic=True,
        source_commit=None,
        repair_rounds=job.repair_rounds,
    )
    save_evidence(store, record)
    for review_type in REQUIRED_REVIEW_FILES:
        record_review(
            store,
            job,
            review_type=review_type,
            reviewer_id="demo-runner",
            verdict=ReviewVerdict.PASS,
            findings=["Synthetic demo review. Not an independent examination of a real build."],
            evidence_ids=[evidence_id],
            provenance=ReviewProvenance.DEMO,
            synthetic=True,
        )
    return record


def _hash_matches(store: JobStore, job_id: str, relative: str, expected: str) -> str | None:
    problem = _path_problem(relative)
    if problem:
        return problem
    try:
        path = store.safe_path(job_id, relative)
    except ValueError as exc:
        return str(exc)
    if not path.is_file():
        if relative.endswith(("stdout.txt", "stderr.txt")):
            return f"missing stdout/stderr evidence: {relative}"
        return f"artifact missing: {relative}"
    actual = sha256_bytes(path.read_bytes())
    if actual != expected:
        return f"artifact hash mismatch (tampered test artifact): {relative}"
    return None


def _markdown_claims_pass(store: JobStore, job_id: str, filename: str) -> bool:
    path = store.job_dir(job_id) / filename
    if not path.is_file():
        return False
    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if stripped.upper().startswith("VERDICT:"):
            return stripped.split(":", 1)[1].strip().upper() == "PASS"
    return False


def verify_approval(store: JobStore, job: JobState, *, production: bool = False) -> VerificationReport:
    problems: list[str] = []
    notes: list[str] = []
    records = load_evidence(store, job.job_id)
    current = [item for item in records if item.job_id == job.job_id and item.build_id == job.build_id]
    other_jobs = [item for item in records if item.job_id != job.job_id]
    earlier = [item for item in records if item.job_id == job.job_id and item.build_id != job.build_id]
    if other_jobs and not current:
        problems.append("test evidence belongs to another job")
    if earlier and not current:
        problems.append("evidence belongs to an earlier build (rework invalidated prior evidence)")

    allow_synthetic = bool(job.demo_mode) and not production
    real_current = [item for item in current if not item.synthetic]
    synthetic_current = [item for item in current if item.synthetic]
    if production and synthetic_current and not real_current:
        problems.append("synthetic evidence cannot qualify production deployment")
    if not allow_synthetic and synthetic_current and not real_current:
        problems.append("synthetic demo evidence cannot qualify a real job")

    pool = current if allow_synthetic else real_current
    qualifying: TestEvidence | None = None
    if not pool:
        problems.append("missing test evidence: no real test execution")
    else:
        qualifying = max(pool, key=lambda item: item.finished_at)
        if qualifying.repair_rounds != job.repair_rounds:
            problems.append("rework invalidated prior evidence")
        if qualifying.exit_code != 0 or qualifying.status != EvidenceStatus.PASSED:
            problems.append(f"latest required test failed (exit {qualifying.exit_code})")
        else:
            if not qualifying.stdout_path or not qualifying.stderr_path:
                problems.append("missing stdout/stderr evidence")
            for relative, digest in qualifying.artifact_hashes.items():
                mismatch = _hash_matches(store, job.job_id, relative, digest)
                if mismatch:
                    problems.append(mismatch)
            for required in (qualifying.stdout_path, qualifying.stderr_path):
                if required not in qualifying.artifact_hashes:
                    problems.append(f"missing stdout/stderr evidence: {required}")

    reviews: list[ReviewRecord] = []
    for review_type, filename in REQUIRED_REVIEW_FILES.items():
        try:
            loaded = load_review(store, job.job_id, review_type)
        except ValueError:
            problems.append(f"invalid structured review {filename}")
            continue
        if loaded is None:
            if _markdown_claims_pass(store, job.job_id, filename):
                problems.append(f"fake PASS text without structured evidence ({filename})")
            else:
                problems.append(f"missing structured review {filename}")
            continue
        raw_path = store.job_dir(job.job_id) / "reviews" / f"{review_type}.json"
        raw_payload = json.loads(raw_path.read_text(encoding="utf-8"))
        stored_hash = str(raw_payload.get("content_hash") or "")
        unsigned = {key: value for key, value in raw_payload.items() if key != "content_hash"}
        if sha256_text(_canonical(unsigned)) != stored_hash:
            problems.append(f"review content hash mismatch: {filename}")
        if loaded.job_id != job.job_id:
            problems.append(f"review belongs to another job: {filename}")
        if loaded.build_id != job.build_id or loaded.repair_rounds != job.repair_rounds:
            problems.append(f"stale review after code change: {filename} references the wrong build")
        if loaded.verdict != ReviewVerdict.PASS:
            problems.append(f"review verdict is CHANGES: {filename}")
        if loaded.synthetic and not allow_synthetic:
            problems.append(f"synthetic review cannot qualify a real job: {filename}")
        if qualifying and qualifying.evidence_id not in loaded.evidence_ids:
            problems.append(f"review references evidence that is not the current passing test: {filename}")
        if qualifying and qualifying.synthetic and not loaded.synthetic and not allow_synthetic:
            problems.append(f"review is not bound to real evidence: {filename}")
        reviews.append(loaded)

    reviewer_ids = {item.reviewer_id for item in reviews}
    provenances = {item.provenance for item in reviews}
    independent = len(reviews) == 3 and len(reviewer_ids) == 3 and provenances == {ReviewProvenance.INDEPENDENT}
    if len(reviews) == 3 and not independent:
        if ReviewProvenance.INDEPENDENT in provenances and len(reviewer_ids) < 3:
            problems.append("reviews claim independent provenance but share one reviewer identity")
        else:
            notes.append(
                "reviews are multiple perspectives"
                + (f" from {next(iter(reviewer_ids))}" if len(reviewer_ids) == 1 else "")
                + "; not recorded as three independently executed reviewers"
            )

    ready = not problems
    return VerificationReport(
        ready=ready,
        problems=problems,
        notes=notes,
        build_id=job.build_id,
        evidence_id=qualifying.evidence_id if qualifying else None,
        reviews_independent=independent,
        synthetic_only=bool(qualifying and qualifying.synthetic and not real_current),
    )
