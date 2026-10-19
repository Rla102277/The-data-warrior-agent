"""Metadata-driven ingestion specifications (D8/D9/D10)."""

from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field, field_validator

from forge.core.models import Layer


class IngestionLoadType(str, Enum):
    FULL = "FULL"
    TRUNCATE_AND_LOAD = "TRUNCATE_AND_LOAD"
    INCREMENTAL = "INCREMENTAL"
    CDC = "CDC"
    SNAPSHOT = "SNAPSHOT"
    FILE = "FILE"
    API = "API"
    EVENT = "EVENT"
    WEB = "WEB"


class RetryPolicy(BaseModel):
    """D9 default: retry_count = 1, timeout 10 minutes for standard stage loads."""

    retry_count: int = 1
    timeout_minutes: int = 10

    @field_validator("retry_count")
    @classmethod
    def non_negative(cls, value: int) -> int:
        if value < 0:
            raise ValueError("retry_count must be >= 0")
        return value


class WatermarkSpec(BaseModel):
    field_name: str
    value: str | None = None
    advance_only_after_validation: bool = True


class IngestionSpec(BaseModel):
    """Declarative ingestion configuration consumed by a reusable engine."""

    spec_id: str
    source_system: str
    source_object: str
    target_workspace: str = "Foundation Development"
    target_lakehouse_or_warehouse: str
    target_schema: Layer | str = Layer.RAW
    target_table: str
    load_type: IngestionLoadType
    connection_reference: str | None = None
    incremental_keys: list[str] = Field(default_factory=list)
    watermark: WatermarkSpec | None = None
    retry: RetryPolicy = Field(default_factory=RetryPolicy)
    validation_rules: list[str] = Field(default_factory=list)
    quarantine_on_fail: bool = True
    schedule_enabled: bool = False
    owner: str | None = None
    dependencies: list[str] = Field(default_factory=list)
    notes: str = ""
    metadata: dict[str, Any] = Field(default_factory=dict)

    @field_validator("target_schema", mode="before")
    @classmethod
    def coerce_schema(cls, value: Any) -> Any:
        if isinstance(value, str):
            lowered = value.lower()
            if lowered in {layer.value for layer in Layer}:
                return Layer(lowered)
        return value

    @field_validator("target_table")
    @classmethod
    def no_dbo_business_table(cls, value: str, info: Any) -> str:
        schema = info.data.get("target_schema")
        schema_value = schema.value if isinstance(schema, Layer) else str(schema or "")
        if schema_value.lower() == "dbo":
            raise ValueError("business objects must not land in dbo (D0/D13)")
        return value

    def to_control_row(self) -> dict[str, Any]:
        """Serialize to a Foundation control-table oriented dictionary."""
        schema = (
            self.target_schema.value
            if isinstance(self.target_schema, Layer)
            else str(self.target_schema)
        )
        return {
            "spec_id": self.spec_id,
            "source_system": self.source_system,
            "source_object": self.source_object,
            "target_workspace": self.target_workspace,
            "target_store": self.target_lakehouse_or_warehouse,
            "target_schema": schema,
            "target_table": self.target_table,
            "default_load_type": self.load_type.value,
            "retry_count": self.retry.retry_count,
            "timeout_minutes": self.retry.timeout_minutes,
            "schedule_enabled": self.schedule_enabled,
            "watermark_field": self.watermark.field_name if self.watermark else None,
            "owner": self.owner,
        }
