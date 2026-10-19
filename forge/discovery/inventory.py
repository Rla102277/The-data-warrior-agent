"""Canonical asset inventory models."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, Field

from forge.core.models import EvidenceStatus, FabricItemType


def utc_now() -> datetime:
    return datetime.now(UTC)


class InventoryAsset(BaseModel):
    asset_id: str = Field(default_factory=lambda: str(uuid4()))
    tenant_id: str | None = None
    workspace_id: str | None = None
    workspace_name: str
    item_id: str | None = None
    item_type: FabricItemType | str
    item_name: str
    folder_path: str | None = None
    definition_version: str | None = None
    retrieval_timestamp: datetime = Field(default_factory=utc_now)
    definition_hash: str | None = None
    source_api: str = "fixture"
    evidence_confidence: EvidenceStatus = EvidenceStatus.INFERRED
    accessible: bool = True
    metadata: dict[str, Any] = Field(default_factory=dict)


class AssetInventory(BaseModel):
    inventory_id: str = Field(default_factory=lambda: str(uuid4()))
    captured_at: datetime = Field(default_factory=utc_now)
    assets: list[InventoryAsset] = Field(default_factory=list)

    def by_workspace(self, workspace_name: str) -> list[InventoryAsset]:
        return [asset for asset in self.assets if asset.workspace_name == workspace_name]

    def compare(self, previous: AssetInventory) -> dict[str, list[str]]:
        """Snapshot comparison that does not treat inaccessible as deleted."""
        prev_keys = {
            (a.workspace_name, a.item_name, str(a.item_type)): a for a in previous.assets if a.accessible
        }
        curr_keys = {
            (a.workspace_name, a.item_name, str(a.item_type)): a for a in self.assets if a.accessible
        }
        added = sorted(f"{w}/{n}" for (w, n, _) in (set(curr_keys) - set(prev_keys)))
        removed = sorted(f"{w}/{n}" for (w, n, _) in (set(prev_keys) - set(curr_keys)))
        inaccessible = sorted(
            f"{a.workspace_name}/{a.item_name}" for a in self.assets if not a.accessible
        )
        return {"added": added, "removed": removed, "inaccessible": inaccessible}
