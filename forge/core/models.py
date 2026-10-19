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


class FabricItemType(str, Enum):
    LAKEHOUSE = "Lakehouse"
    WAREHOUSE = "Warehouse"
    PIPELINE = "DataPipeline"
    NOTEBOOK = "Notebook"
    SEMANTIC_MODEL = "SemanticModel"
    REPORT = "Report"
    DATAFLOW = "Dataflow"
    VARIABLE_LIBRARY = "VariableLibrary"
    DATA_AGENT = "DataAgent"
    COPY_JOB = "CopyJob"
    EVENTSTREAM = "Eventstream"
    EVENTHOUSE = "Eventhouse"
    SQL_DATABASE = "SQLDatabase"
    UNKNOWN = "Unknown"


# Binding D13 workspace names.
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

ALLOWED_ITEM_PREFIXES = (
    "lake_house_",
    "warehouse_",
    "pipeline_",
    "notebook_",
    "semantic_model_",
    "variable_library_",
    "data_agent_",
    "report_",
)

BANNED_ITEM_PREFIXES = ("pl_", "lh_", "wh_", "sm_", "nb_", "ai_", "da_", "EDW_", "dim_", "fact_", "vw_")

TABLE_SHAPES = frozenset({"obt", "sum", "det", "hist", "map"})


class WorkspaceRef(BaseModel):
    """Reference to a Fabric workspace by approved name and optional id."""

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


class FabricItemRef(BaseModel):
    workspace: WorkspaceRef
    name: str
    item_type: FabricItemType = FabricItemType.UNKNOWN
    item_id: str | None = None
    folder_path: str | None = None

    @field_validator("name")
    @classmethod
    def strip_name(cls, value: str) -> str:
        return value.strip()


class SourceSystemRef(BaseModel):
    system_id: str
    display_name: str
    connection_reference: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)
