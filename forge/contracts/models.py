"""ODCS-aligned data contract models."""

from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class CompatibilityClass(str, Enum):
    BACKWARD = "backward"
    FORWARD = "forward"
    BREAKING = "breaking"
    UNKNOWN = "unknown"


class SchemaField(BaseModel):
    name: str
    data_type: str
    nullable: bool = True
    precision: int | None = None
    scale: int | None = None
    description: str | None = None
    classification: str | None = None


class DataContract(BaseModel):
    contract_id: str
    dataset_identity: str
    version: str
    owner: str
    business_meaning: str
    schema_fields: list[SchemaField] = Field(default_factory=list)
    keys: list[str] = Field(default_factory=list)
    relationships: list[dict[str, Any]] = Field(default_factory=list)
    freshness_sla_minutes: int | None = None
    quality_requirements: list[str] = Field(default_factory=list)
    compatibility_policy: CompatibilityClass = CompatibilityClass.BACKWARD
    downstream_consumers: list[str] = Field(default_factory=list)
    status: str = "proposal"
    metadata: dict[str, Any] = Field(default_factory=dict)

    def compare_schema(self, other: DataContract) -> CompatibilityClass:
        """Naive compatibility classification for contract evolution."""
        self_fields = {field.name: field for field in self.schema_fields}
        other_fields = {field.name: field for field in other.schema_fields}
        removed = set(self_fields) - set(other_fields)
        added = set(other_fields) - set(self_fields)
        type_changed = [
            name
            for name in set(self_fields) & set(other_fields)
            if self_fields[name].data_type != other_fields[name].data_type
            or self_fields[name].nullable != other_fields[name].nullable
        ]
        if removed or type_changed:
            return CompatibilityClass.BREAKING
        if added:
            return CompatibilityClass.FORWARD
        return CompatibilityClass.BACKWARD
