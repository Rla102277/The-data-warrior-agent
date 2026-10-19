"""Control-plane entities aligned to warehouse_stage.control tables."""

from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field, field_validator


class LoadType(str, Enum):
    AUTO = "AUTO"
    FULL = "FULL"
    TRUNCATE_LOAD = "TRUNCATE_LOAD"
    INCREMENTAL = "INCREMENTAL"


class RunGroup(str, Enum):
    STANDARD = "standard"
    HISTORY = "history"


class StageLoadConfig(BaseModel):
    """Row shape for control.stage_load_config (D8/D9/D10)."""

    target_name: str
    current_name: str
    schema_name: str = "transform"
    shape: str
    proc_name_current: str
    proc_name_target: str
    default_load_type: LoadType
    watermark_source: str | None = None
    run_group: RunGroup = RunGroup.STANDARD
    run_wave: int
    timeout_minutes: int = 10
    retry_count: int = 1
    is_active: bool = True
    notes: str | None = None

    @field_validator("schema_name")
    @classmethod
    def no_dbo(cls, value: str) -> str:
        if value.lower() == "dbo":
            raise ValueError("control metadata must not place business objects in dbo")
        return value

    @field_validator("retry_count")
    @classmethod
    def d9_non_negative(cls, value: int) -> int:
        if value < 0:
            raise ValueError("retry_count must be >= 0")
        return value


class ExecutionRecord(BaseModel):
    execution_id: str
    pipeline_name: str
    pipeline_run_id: str
    target_name: str | None = None
    status: str
    started_at: str | None = None
    ended_at: str | None = None
    attempt: int = 1
    metadata: dict[str, Any] = Field(default_factory=dict)


class ControlPlaneDecision(BaseModel):
    """Recorded architectural choice for where control state lives."""

    store: str = "warehouse_stage.control"
    parallel_database_allowed: bool = False
    rationale: str = (
        "Reuse established Fabric warehouse_stage control tables; "
        "avoid a second parallel control database without demonstrated need."
    )
    evidence: list[str] = Field(
        default_factory=lambda: [
            "automation/sql/stage_load_config.sql",
            "automation/sql/wh_stage_setup.sql",
            "knowledge/decisions/README.md (D8, D9, D10)",
        ]
    )
