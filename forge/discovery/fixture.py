"""Load a tool-neutral inventory fixture. No vendor client is called."""

from __future__ import annotations

from pathlib import Path

import yaml

from forge.discovery.inventory import AssetInventory, InventoryAsset


class FixtureInventory:
    def __init__(self, path: str | Path) -> None:
        self.path = Path(path)

    def discover(self) -> AssetInventory:
        payload = yaml.safe_load(self.path.read_text(encoding="utf-8")) or {}
        assets = [InventoryAsset.model_validate(row) for row in payload.get("assets") or []]
        return AssetInventory(assets=assets)
