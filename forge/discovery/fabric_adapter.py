"""Fabric discovery adapters.

Live Fabric discovery uses injected clients. Importing this module never
authenticates. Missing credentials use the mock adapter and fixtures.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from pathlib import Path
from typing import Any, Protocol

import yaml

from forge.core.models import EvidenceStatus, FabricItemType
from forge.discovery.inventory import AssetInventory, InventoryAsset
from forge.exceptions import DiscoveryError


class FabricClient(Protocol):
    def list_workspaces(self) -> list[dict[str, Any]]: ...

    def list_items(self, workspace_id: str) -> list[dict[str, Any]]: ...


class FabricDiscoveryAdapter(ABC):
    @abstractmethod
    def discover(self) -> AssetInventory:
        raise NotImplementedError


class MockFabricDiscoveryAdapter(FabricDiscoveryAdapter):
    """Read-only discovery from YAML/JSON fixtures for offline tests."""

    def __init__(self, fixture_path: str | Path) -> None:
        self.fixture_path = Path(fixture_path)

    def discover(self) -> AssetInventory:
        if not self.fixture_path.exists():
            raise DiscoveryError(f"fixture not found: {self.fixture_path}")
        payload = yaml.safe_load(self.fixture_path.read_text()) or {}
        assets: list[InventoryAsset] = []
        for row in payload.get("assets", []):
            assets.append(
                InventoryAsset(
                    tenant_id=row.get("tenant_id"),
                    workspace_id=row.get("workspace_id"),
                    workspace_name=row["workspace_name"],
                    item_id=row.get("item_id"),
                    item_type=_coerce_item_type(row.get("item_type", "Unknown")),
                    item_name=row["item_name"],
                    folder_path=row.get("folder_path"),
                    definition_version=row.get("definition_version"),
                    definition_hash=row.get("definition_hash"),
                    source_api=row.get("source_api", "fixture"),
                    evidence_confidence=EvidenceStatus(
                        row.get("evidence_confidence", EvidenceStatus.INFERRED.value)
                    ),
                    accessible=bool(row.get("accessible", True)),
                    metadata=row.get("metadata") or {},
                )
            )
        return AssetInventory(assets=assets)


class InjectedFabricDiscoveryAdapter(FabricDiscoveryAdapter):
    """Live discovery via injected client (dependency injection for tests/mocks)."""

    def __init__(self, client: FabricClient, *, tenant_id: str | None = None) -> None:
        self.client = client
        self.tenant_id = tenant_id

    def discover(self) -> AssetInventory:
        assets: list[InventoryAsset] = []
        for workspace in self.client.list_workspaces():
            workspace_id = str(workspace.get("id") or "")
            workspace_name = str(workspace.get("name") or "")
            try:
                items = self.client.list_items(workspace_id)
                accessible = True
            except Exception as exc:  # noqa: BLE001 - boundary adapter
                assets.append(
                    InventoryAsset(
                        tenant_id=self.tenant_id,
                        workspace_id=workspace_id,
                        workspace_name=workspace_name,
                        item_type=FabricItemType.UNKNOWN,
                        item_name="__workspace_inaccessible__",
                        source_api="fabric_api",
                        evidence_confidence=EvidenceStatus.UNKNOWN,
                        accessible=False,
                        metadata={"error": str(exc)},
                    )
                )
                continue
            for item in items:
                assets.append(
                    InventoryAsset(
                        tenant_id=self.tenant_id,
                        workspace_id=workspace_id,
                        workspace_name=workspace_name,
                        item_id=str(item.get("id") or "") or None,
                        item_type=_coerce_item_type(item.get("type", "Unknown")),
                        item_name=str(item.get("displayName") or item.get("name") or ""),
                        folder_path=item.get("folderPath"),
                        source_api="fabric_api",
                        evidence_confidence=EvidenceStatus.CONFIRMED,
                        accessible=accessible,
                    )
                )
        return AssetInventory(assets=assets)


def _coerce_item_type(raw: Any) -> FabricItemType | str:
    text = str(raw)
    try:
        return FabricItemType(text)
    except ValueError:
        for member in FabricItemType:
            if member.value.lower() == text.lower() or member.name.lower() == text.lower():
                return member
        return text
