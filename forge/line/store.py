"""Filesystem job store. Survives process restarts."""

from __future__ import annotations

import json
from pathlib import Path

from forge.line.models import JobState


class JobStore:
    """Persist jobs under forge-line/jobs/<job_id>/job.json."""

    def __init__(self, root: str | Path = "forge-line/jobs") -> None:
        self.root = Path(root)
        self.root.mkdir(parents=True, exist_ok=True)

    def job_dir(self, job_id: str) -> Path:
        path = self.root / job_id
        path.mkdir(parents=True, exist_ok=True)
        return path

    def save(self, job: JobState) -> Path:
        job.touch()
        directory = self.job_dir(job.job_id)
        path = directory / "job.json"
        path.write_text(job.model_dump_json(indent=2))
        # Lightweight board index for dashboard
        self._rewrite_board()
        return path

    def load(self, job_id: str) -> JobState:
        path = self.root / job_id / "job.json"
        if not path.exists():
            raise FileNotFoundError(f"Job not found: {job_id}")
        return JobState.model_validate_json(path.read_text())

    def list_jobs(self) -> list[JobState]:
        jobs: list[JobState] = []
        if not self.root.exists():
            return jobs
        for child in sorted(self.root.iterdir()):
            if child.is_dir() and (child / "job.json").exists():
                jobs.append(JobState.model_validate_json((child / "job.json").read_text()))
        return jobs

    def safe_path(self, job_id: str, relative: str) -> Path:
        rel = Path(relative)
        if rel.is_absolute() or ".." in rel.parts:
            raise ValueError(f"refusing path outside job directory: {relative}")
        root = self.job_dir(job_id).resolve()
        path = (root / rel).resolve()
        if not path.is_relative_to(root):
            raise ValueError(f"refusing path outside job directory: {relative}")
        return path

    def write_artifact(self, job_id: str, name: str, content: str) -> Path:
        path = self.safe_path(job_id, name)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def _rewrite_board(self) -> None:
        board = {
            "jobs": [
                {
                    "id": job.job_id,
                    "title": job.title,
                    "stage": job.stage.value,
                    "autonomy_level": int(job.autonomy_level),
                    "platform_profile": job.platform_profile,
                    "attempt_count": job.attempt_count,
                    "repair_rounds": job.repair_rounds,
                    "updated_at": job.updated_at.isoformat(),
                }
                for job in self.list_jobs()
            ]
        }
        board_path = self.root.parent / "board.json"
        board_path.write_text(json.dumps(board, indent=2))
