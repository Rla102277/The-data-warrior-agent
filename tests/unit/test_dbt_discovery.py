from __future__ import annotations

from pathlib import Path

from discovery.dbt import DbtDiscovery

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / "tests/fixtures/dbt/sample_manifest.json"


def test_dbt_discover_models_sources_and_naming() -> None:
    inventory = DbtDiscovery().discover(manifest_path=FIXTURE)
    assert inventory.project_name == "forge"
    assert inventory.model_count == 5
    assert inventory.source_count == 1
    assert inventory.test_count == 1
    assert any("dim_customer" in item for item in inventory.naming_violations)
    # D19 exception: market_dim_community is not treated as a violation.
    assert not any("market_dim_community" in item for item in inventory.naming_violations)


def test_dbt_impact_analysis() -> None:
    discovery = DbtDiscovery()
    inventory = discovery.discover(manifest_path=FIXTURE)
    impact = discovery.impact("sale_obt", inventory)
    assert "model.forge.sale" in impact["downstream"]
    assert "model.forge.project" in impact["downstream"]
