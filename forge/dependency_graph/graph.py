"""Lightweight in-memory dependency graph (NetworkX)."""

from __future__ import annotations

from collections.abc import Iterable
from datetime import UTC, datetime
from enum import Enum
from typing import Any
from uuid import uuid4

import networkx as nx
from pydantic import BaseModel, Field

from forge.core.models import EvidenceStatus


def utc_now() -> datetime:
    return datetime.now(UTC)


class RelationType(str, Enum):
    DEPENDS_ON = "depends_on"
    READS_FROM = "reads_from"
    WRITES_TO = "writes_to"
    TRANSFORMS = "transforms"
    INVOKES = "invokes"
    PUBLISHES = "publishes"
    CONSUMES = "consumes"
    OWNED_BY = "owned_by"
    GOVERNED_BY = "governed_by"
    DEPLOYED_TO = "deployed_to"
    SUPERSEDES = "supersedes"
    VALIDATED_AGAINST = "validated_against"


class GraphNode(BaseModel):
    node_id: str
    node_type: str
    name: str
    metadata: dict[str, Any] = Field(default_factory=dict)


class DependencyRelation(BaseModel):
    relation_id: str = Field(default_factory=lambda: str(uuid4()))
    source: str
    destination: str
    relationship_type: RelationType
    evidence: str
    evidence_status: EvidenceStatus = EvidenceStatus.INFERRED
    timestamp: datetime = Field(default_factory=utc_now)
    source_version: str | None = None


class DependencyGraph:
    def __init__(self) -> None:
        self._graph = nx.DiGraph()
        self._relations: list[DependencyRelation] = []

    def add_node(self, node: GraphNode) -> None:
        self._graph.add_node(node.node_id, **node.model_dump())

    def add_relation(self, relation: DependencyRelation) -> None:
        if relation.source not in self._graph:
            self._graph.add_node(relation.source, node_id=relation.source, node_type="unknown", name=relation.source)
        if relation.destination not in self._graph:
            self._graph.add_node(
                relation.destination,
                node_id=relation.destination,
                node_type="unknown",
                name=relation.destination,
            )
        self._graph.add_edge(
            relation.source,
            relation.destination,
            relationship_type=relation.relationship_type.value,
            evidence=relation.evidence,
            evidence_status=relation.evidence_status.value,
        )
        self._relations.append(relation)

    def upstream(self, node_id: str) -> list[str]:
        if node_id not in self._graph:
            return []
        return sorted(nx.ancestors(self._graph, node_id))

    def downstream(self, node_id: str) -> list[str]:
        if node_id not in self._graph:
            return []
        return sorted(nx.descendants(self._graph, node_id))

    def cycles(self) -> list[list[str]]:
        try:
            return [list(cycle) for cycle in nx.simple_cycles(self._graph)]
        except nx.NetworkXNoCycle:
            return []

    def orphans(self) -> list[str]:
        return sorted(node for node in self._graph.nodes if self._graph.degree(node) == 0)

    def impact(self, node_id: str) -> dict[str, list[str]]:
        return {
            "upstream": self.upstream(node_id),
            "downstream": self.downstream(node_id),
        }

    def relations(self) -> list[DependencyRelation]:
        return list(self._relations)

    def extend(self, relations: Iterable[DependencyRelation]) -> None:
        for relation in relations:
            self.add_relation(relation)
