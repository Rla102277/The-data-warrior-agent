"""Environment-backed settings with safe, platform-neutral defaults."""

from __future__ import annotations

import os
from pathlib import Path

from pydantic import BaseModel, Field


class ForgeSettings(BaseModel):
    env: str = "local"
    log_level: str = "INFO"
    default_workspace: str = "Forge Development"
    prod_workspace: str = "Forge Production"
    governance_workspace: str = "Forge Governance"
    discovery_fixture_dir: Path = Field(default_factory=lambda: Path("tests/fixtures"))
    repo_root: Path = Field(default_factory=lambda: Path.cwd())


# Backward-compatible alias for imports that still use the old name.
FoundationSettings = ForgeSettings


def _env(environ: dict[str, str], forge_key: str, legacy_key: str, default: str) -> str:
    return environ.get(forge_key) or environ.get(legacy_key) or default


def load_settings(environ: dict[str, str] | None = None) -> ForgeSettings:
    env = environ if environ is not None else os.environ
    fixture = _env(env, "FORGE_DISCOVERY_FIXTURE_DIR", "FOUNDATION_DISCOVERY_FIXTURE_DIR", "tests/fixtures")
    return ForgeSettings(
        env=_env(env, "FORGE_ENV", "FOUNDATION_ENV", "local"),
        log_level=_env(env, "FORGE_LOG_LEVEL", "FOUNDATION_LOG_LEVEL", "INFO"),
        default_workspace=_env(
            env, "FORGE_DEFAULT_WORKSPACE", "FOUNDATION_DEFAULT_WORKSPACE", "Forge Development"
        ),
        prod_workspace=_env(
            env, "FORGE_PROD_WORKSPACE", "FOUNDATION_PROD_WORKSPACE", "Forge Production"
        ),
        governance_workspace=_env(
            env,
            "FORGE_GOVERNANCE_WORKSPACE",
            "FOUNDATION_GOVERNANCE_WORKSPACE",
            "Forge Governance",
        ),
        discovery_fixture_dir=Path(fixture),
        repo_root=Path(_env(env, "FORGE_REPO_ROOT", "FOUNDATION_REPO_ROOT", str(Path.cwd()))),
    )
