"""Discovery, ADF IR, and dependency graph tests."""

from __future__ import annotations

from pathlib import Path

from discovery.adf.parser import AdfPipelineParser
from forge.core.models import EvidenceStatus
from forge.dependency_graph import DependencyGraph
from forge.discovery import MockFabricDiscoveryAdapter

ROOT = Path(__file__).resolve().parents[2]


def test_fabric_fixture_discovery() -> None:
    inventory = MockFabricDiscoveryAdapter(ROOT / "tests/fixtures/fabric/sample_inventory.yaml").discover()
    assert len(inventory.assets) == 4
    fd = inventory.by_workspace("Foundation Development")
    assert any(asset.item_name == "lake_house_analytics" for asset in fd)
    inaccessible = [asset for asset in inventory.assets if not asset.accessible]
    assert len(inaccessible) == 1


def test_inventory_compare_does_not_treat_inaccessible_as_deleted() -> None:
    adapter = MockFabricDiscoveryAdapter(ROOT / "tests/fixtures/fabric/sample_inventory.yaml")
    current = adapter.discover()
    previous = adapter.discover()
    # Mark one accessible asset as removed from previous only.
    previous.assets = [asset for asset in previous.assets if asset.item_name != "lake_house_web"]
    diff = current.compare(previous)
    assert "inaccessible" in diff
    assert any("Operations" in item for item in diff["inaccessible"])


def test_adf_parser_builds_ir_and_graph() -> None:
    parser = AdfPipelineParser()
    ir = parser.parse_file(ROOT / "tests/fixtures/adf/sample_pipeline.json")
    assert ir.pipeline_name == "pl_legacy_stage_entity_load"
    assert ir.evidence_status == EvidenceStatus.CONFIRMED
    assert any(activity.name == "CopyEntity" for activity in ir.activities)
    assert "dataset:ds_source_entity" in ir.input_dependencies
    relations = parser.extract_dependency_relations(ir)
    graph = DependencyGraph()
    graph.extend(relations)
    impact = graph.impact(ir.asset_identity)
    assert "dataset:ds_source_entity" in impact["downstream"] or "dataset:ds_stage_entity" in impact["downstream"]
    assert graph.cycles() == []
