"""Environment-backed settings with safe defaults."""

from __future__ import annotations

import os
from pathlib import Path

from pydantic import BaseModel, Field


class FoundationSettings(BaseModel):
    env: str = "local"
    log_level: str = "INFO"
    default_workspace: str = "Foundation Development"
    prod_workspace: str = "Foundation"
    governance_workspace: str = "Foundation Governance"
    discovery_fixture_dir: Path = Field(default_factory=lambda: Path("tests/fixtures"))
    repo_root: Path = Field(default_factory=lambda: Path.cwd())


def load_settings(environ: dict[str, str] | None = None) -> FoundationSettings:
    env = environ if environ is not None else os.environ
    fixture = env.get("FOUNDATION_DISCOVERY_FIXTURE_DIR", "tests/fixtures")
    return FoundationSettings(
        env=env.get("FOUNDATION_ENV", "local"),
        log_level=env.get("FOUNDATION_LOG_LEVEL", "INFO"),
        default_workspace=env.get("FOUNDATION_DEFAULT_WORKSPACE", "Foundation Development"),
        prod_workspace=env.get("FOUNDATION_PROD_WORKSPACE", "Foundation"),
        governance_workspace=env.get(
            "FOUNDATION_GOVERNANCE_WORKSPACE", "Foundation Governance"
        ),
        discovery_fixture_dir=Path(fixture),
        repo_root=Path(env.get("FOUNDATION_REPO_ROOT", Path.cwd())),
    )
