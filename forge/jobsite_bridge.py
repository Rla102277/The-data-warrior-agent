"""Jobsite bridge during Forge Line cutover.

Jobsite is sunset as a brand. Forge Line (`factory/`) is the successor.
This module remains as a temporary compatibility status helper until M11 removes
the dual-runtime bridge.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field


class JobsiteBridgeStatus(BaseModel):
    foundation_owned: bool = True
    successor: str = "Forge Line"
    successor_path: str = "factory/"
    legacy_runtime_path: str = "jobsite/"
    sdk_path: str = "forge/"
    absorption_status: str = "sunset_in_progress"
    role_mapping: dict[str, str] = Field(
        default_factory=lambda: {
            "factory-director": "forge_supervisor",
            "data-discovery": "discovery",
            "fabric-engineer": "fabric_engineer",
            "dbt": "dbt_engineer",
            "data-quality": "data_quality",
            "data-reconciliation": "data_quality",
            "reviewer-security": "security",
            "approver": "release",
        }
    )
    notes: list[str] = Field(
        default_factory=lambda: [
            "Forge Line owns job lifecycle, state machine, and Cursor /factory loop.",
            "Foundation SDK owns policies, discovery parsers, control-plane models, and CLI.",
            "Jobsite brand is deprecated; do not add features to legacy jobsite/.",
            "FD Fabric apply still requires machine policy APPROVE + D12 rules.",
        ]
    )


def jobsite_bridge_status(*, repo_root: str | Path | None = None) -> JobsiteBridgeStatus:
    root = Path(repo_root) if repo_root else Path.cwd()
    status = JobsiteBridgeStatus()
    factory_runtime = root / "factory"
    if factory_runtime.exists():
        status.absorption_status = "successor_present"
        status.notes.append("factory/ present in this checkout (Forge Line home)")
    if (root / "jobsite" / "orchestrator" / "jobsite.py").exists():
        status.notes.append("legacy jobsite/ still present; treat as read-only until M11")
    else:
        status.notes.append("legacy jobsite/orchestrator not in this checkout (expected for Foundation 2.0)")
    return status


def jobsite_bridge_dict() -> dict[str, Any]:
    return jobsite_bridge_status().model_dump()
