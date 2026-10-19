"""Read dbt manifest.json / catalog.json without mutating models."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field

from forge.core.models import EvidenceStatus
from forge.dependency_graph.graph import DependencyGraph, DependencyRelation, RelationType
from forge.exceptions import DiscoveryError
from forge.policies.naming import lint_naming_text


class DbtModelSummary(BaseModel):
    unique_id: str
    name: str
    resource_type: str
    package_name: str | None = None
    schema_name: str | None = None
    database: str | None = None
    materialized: str | None = None
    path: str | None = None
    description: str = ""
    depends_on_nodes: list[str] = Field(default_factory=list)
    tags: list[str] = Field(default_factory=list)
    columns: list[str] = Field(default_factory=list)
    naming_findings: list[str] = Field(default_factory=list)


class DbtSourceSummary(BaseModel):
    unique_id: str
    name: str
    source_name: str
    schema_name: str | None = None
    database: str | None = None
    path: str | None = None


class DbtProjectInventory(BaseModel):
    project_name: str
    dbt_version: str | None = None
    model_count: int = 0
    source_count: int = 0
    test_count: int = 0
    exposure_count: int = 0
    models: list[DbtModelSummary] = Field(default_factory=list)
    sources: list[DbtSourceSummary] = Field(default_factory=list)
    naming_violations: list[str] = Field(default_factory=list)
    evidence_status: EvidenceStatus = EvidenceStatus.CONFIRMED
    manifest_path: str | None = None
    catalog_loaded: bool = False


class DbtDiscovery:
    """Discover Foundation dbt project assets from compiled artifacts."""

    def __init__(self, project_dir: str | Path | None = None) -> None:
        self.project_dir = Path(project_dir) if project_dir else Path("dbt")

    def discover(
        self,
        *,
        manifest_path: str | Path | None = None,
        catalog_path: str | Path | None = None,
    ) -> DbtProjectInventory:
        manifest_file = Path(manifest_path) if manifest_path else self.project_dir / "target" / "manifest.json"
        if not manifest_file.exists():
            raise DiscoveryError(f"dbt manifest not found: {manifest_file}")
        manifest = json.loads(manifest_file.read_text())
        catalog: dict[str, Any] = {}
        catalog_file = Path(catalog_path) if catalog_path else self.project_dir / "target" / "catalog.json"
        catalog_loaded = False
        if catalog_file.exists():
            catalog = json.loads(catalog_file.read_text())
            catalog_loaded = True

        metadata = manifest.get("metadata") or {}
        project_name = str(metadata.get("project_name") or "foundation")
        nodes = manifest.get("nodes") or {}
        sources_raw = manifest.get("sources") or {}
        exposures = manifest.get("exposures") or {}

        models: list[DbtModelSummary] = []
        naming_violations: list[str] = []
        test_count = 0
        for unique_id, node in nodes.items():
            resource_type = str(node.get("resource_type") or "")
            if resource_type == "test":
                test_count += 1
                continue
            if resource_type != "model":
                continue
            name = str(node.get("name") or "")
            findings = lint_naming_text(name)
            # D19 documented market_dim_* exceptions stay as findings only when banned tokens appear;
            # market_dim_community is an approved exception in the decision log.
            if name.startswith("market_dim_"):
                findings = [f for f in findings if "dim_" not in f]
            summary = DbtModelSummary(
                unique_id=unique_id,
                name=name,
                resource_type=resource_type,
                package_name=node.get("package_name"),
                schema_name=node.get("schema"),
                database=node.get("database"),
                materialized=(node.get("config") or {}).get("materialized"),
                path=node.get("original_file_path") or node.get("path"),
                description=str(node.get("description") or ""),
                depends_on_nodes=list((node.get("depends_on") or {}).get("nodes") or []),
                tags=list(node.get("tags") or []),
                columns=self._columns_for(unique_id, node, catalog),
                naming_findings=findings,
            )
            models.append(summary)
            for finding in findings:
                naming_violations.append(f"{name}: {finding}")

        sources = [
            DbtSourceSummary(
                unique_id=unique_id,
                name=str(src.get("name") or ""),
                source_name=str(src.get("source_name") or ""),
                schema_name=src.get("schema"),
                database=src.get("database"),
                path=src.get("original_file_path") or src.get("path"),
            )
            for unique_id, src in sources_raw.items()
        ]

        return DbtProjectInventory(
            project_name=project_name,
            dbt_version=metadata.get("dbt_version"),
            model_count=len(models),
            source_count=len(sources),
            test_count=test_count,
            exposure_count=len(exposures),
            models=sorted(models, key=lambda item: item.name),
            sources=sorted(sources, key=lambda item: item.unique_id),
            naming_violations=naming_violations,
            evidence_status=EvidenceStatus.CONFIRMED,
            manifest_path=str(manifest_file),
            catalog_loaded=catalog_loaded,
        )

    def lineage_graph(self, inventory: DbtProjectInventory | None = None) -> DependencyGraph:
        inv = inventory or self.discover()
        graph = DependencyGraph()
        for model in inv.models:
            for parent in model.depends_on_nodes:
                graph.add_relation(
                    DependencyRelation(
                        source=model.unique_id,
                        destination=parent,
                        relationship_type=RelationType.DEPENDS_ON,
                        evidence=inv.manifest_path or "dbt_manifest",
                        evidence_status=EvidenceStatus.CONFIRMED,
                        source_version=inv.dbt_version,
                    )
                )
        return graph

    def impact(self, model_name_or_id: str, inventory: DbtProjectInventory | None = None) -> dict[str, list[str]]:
        inv = inventory or self.discover()
        graph = self.lineage_graph(inv)
        node_id = model_name_or_id
        if not node_id.startswith("model."):
            matches = [m.unique_id for m in inv.models if m.name == model_name_or_id]
            if not matches:
                raise DiscoveryError(f"dbt model not found: {model_name_or_id}")
            node_id = matches[0]
        return graph.impact(node_id)

    @staticmethod
    def _columns_for(unique_id: str, node: dict[str, Any], catalog: dict[str, Any]) -> list[str]:
        columns = node.get("columns") or {}
        if columns:
            return sorted(columns.keys())
        catalog_nodes = catalog.get("nodes") or {}
        catalog_entry = catalog_nodes.get(unique_id) or {}
        catalog_cols = catalog_entry.get("columns") or {}
        return sorted(catalog_cols.keys())
