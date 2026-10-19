"""Core identity and reference models."""

from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field, field_validator


class EvidenceStatus(str, Enum):
    CONFIRMED = "CONFIRMED"
    INFERRED = "INFERRED"
    UNKNOWN = "UNKNOWN"


class Environment(str, Enum):
    LOCAL = "local"
    FOUNDATION_DEVELOPMENT = "foundation_development"
    FOUNDATION = "foundation"
    FOUNDATION_GOVERNANCE = "foundation_governance"
    LEGACY = "legacy"


class Layer(str, Enum):
    RAW = "raw"
    STAGE = "stage"
    CONTROL = "control"
    TRANSFORM = "transform"
    ANALYTICS = "analytics"


# Binding workspace names for the optional estate policy adapter.
APPROVED_WORKSPACES = frozenset(
    {
        "Foundation Development",
        "Foundation",
        "Foundation Governance",
    }
)

LEGACY_WORKSPACES = frozenset(
    {
        "Operations",
        "Operations-Dev",
        "Finance",
        "Finance-Dev",
        "GBP-Enterprise",
        "GBP-Enterprise-Dev",
        "DataSources",
        "Audit-Dev",
    }
)

TABLE_SHAPES = frozenset({"obt", "sum", "det", "hist", "map"})


class WorkspaceRef(BaseModel):
    """Named workspace. The platform is chosen on the ground, not here."""

    name: str
    workspace_id: str | None = None
    environment: Environment = Environment.FOUNDATION_DEVELOPMENT

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        return value.strip()

    @property
    def is_approved_foundation(self) -> bool:
        return self.name in APPROVED_WORKSPACES

    @property
    def is_legacy(self) -> bool:
        return self.name in LEGACY_WORKSPACES or self.environment == Environment.LEGACY


class SourceSystemRef(BaseModel):
    system_id: str
    display_name: str
    connection_reference: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
