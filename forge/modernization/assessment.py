"""ADF fixture modernization assessment with evidence and D-decision mapping.

Implements the modernization bar:
1. Read pipeline definition
2. Extract source/target/transform/deps (via Canonical IR)
3. Valid IR
4. Applicable D-decision map
5. Migration assessment with evidence
6. Executable replacement test hints
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field

from discovery.adf.parser import AdfPipelineParser, CanonicalPipelineIR
from forge.core.models import EvidenceStatus
from forge.dependency_graph import DependencyGraph
from forge.policies import PolicyDecision, evaluate_action


class DecisionHit(BaseModel):
    decision_id: str
    relevance: str
    evidence_status: EvidenceStatus = EvidenceStatus.CONFIRMED


class MigrationAssessment(BaseModel):
    pipeline_name: str
    asset_identity: str
    ir_version: str
    source_path: str | None
    applicable_decisions: list[DecisionHit]
    recommendation: str
    blockers: list[str] = Field(default_factory=list)
    cutover_allowed: bool = False
    evidence: list[str] = Field(default_factory=list)
    evidence_status: EvidenceStatus = EvidenceStatus.CONFIRMED
    replacement_tests: list[str] = Field(default_factory=list)
    dependency_summary: dict[str, Any] = Field(default_factory=dict)
    ir: dict[str, Any] = Field(default_factory=dict)
    policy_probe: dict[str, Any] = Field(default_factory=dict)


class ModernizationAssessor:
    """Assess an ADF pipeline JSON for Foundation-compliant modernization."""

    def __init__(self, parser: AdfPipelineParser | None = None) -> None:
        self._parser = parser or AdfPipelineParser()

    def assess_file(self, path: str | Path) -> MigrationAssessment:
        ir = self._parser.parse_file(path)
        return self.assess_ir(ir)

    def assess_ir(self, ir: CanonicalPipelineIR) -> MigrationAssessment:
        decisions = self._map_decisions(ir)
        graph = DependencyGraph()
        relations = self._parser.extract_dependency_relations(ir)
        graph.extend(relations)

        cutover_policy = evaluate_action(
            actor="modernization_assessor",
            action="modernization_cutover",
            target={"workspace": "Foundation", "name": ir.pipeline_name},
            environment="foundation",
        )
        blockers: list[str] = []
        if cutover_policy.decision != PolicyDecision.ALLOW:
            blockers.extend(cutover_policy.reasons)

        # InvokePipeline fleets are incompatible with D10 metadata orchestration preference.
        execute_count = sum(1 for a in ir.activities if a.activity_type == "ExecutePipeline")
        if execute_count:
            decisions.append(
                DecisionHit(
                    decision_id="D10",
                    relevance=(
                        f"Pipeline invokes {execute_count} child pipeline(s); "
                        "prefer metadata-driven orchestration over InvokePipeline fleets."
                    ),
                    evidence_status=EvidenceStatus.CONFIRMED,
                )
            )

        if ir.compatibility_findings:
            blockers.extend(ir.compatibility_findings)

        recommendation = (
            "Map to Foundation metadata-driven stage load (D10) in Foundation Development; "
            "preserve D8/D9 load semantics; do not cut over production without D12 item approval."
        )
        if "pl_" in ir.pipeline_name or ir.pipeline_name.startswith("pl_"):
            decisions.append(
                DecisionHit(
                    decision_id="D13",
                    relevance="Legacy pl_ prefix must become pipeline_* in new Foundation Development work.",
                    evidence_status=EvidenceStatus.CONFIRMED,
                )
            )

        replacement_tests = [
            "test_ir_parses_sample_pipeline",
            "test_dependency_graph_from_adf",
            "test_cutover_denied_without_approval",
            "test_d13_rejects_pl_prefix_on_create",
        ]

        return MigrationAssessment(
            pipeline_name=ir.pipeline_name,
            asset_identity=ir.asset_identity,
            ir_version=ir.ir_version,
            source_path=ir.source_definition_path,
            applicable_decisions=decisions,
            recommendation=recommendation,
            blockers=blockers,
            cutover_allowed=False,
            evidence=[p for p in [ir.source_definition_path] if p] + ir.evidence_references,
            evidence_status=EvidenceStatus.CONFIRMED,
            replacement_tests=replacement_tests,
            dependency_summary={
                "relation_count": len(relations),
                "inputs": ir.input_dependencies,
                "outputs": ir.output_dependencies,
                "cycles": graph.cycles(),
            },
            ir=ir.model_dump(mode="json"),
            policy_probe=cutover_policy.model_dump(),
        )

    @staticmethod
    def _map_decisions(ir: CanonicalPipelineIR) -> list[DecisionHit]:
        hits = [
            DecisionHit(
                decision_id="D10",
                relevance="Prefer metadata-driven orchestration over per-entity wrapper pipelines.",
            ),
            DecisionHit(
                decision_id="D12",
                relevance="No production/legacy cutover without item-level written authorization.",
            ),
            DecisionHit(
                decision_id="D13",
                relevance="Name new objects in words the team can read. The ground names the tool; this repo does not prescribe a vendor prefix.",
            ),
        ]
        # Lookup + Copy pattern often maps to stage_load_config control rows (D8/D9).
        types = {a.activity_type for a in ir.activities}
        if "Lookup" in types and "Copy" in types:
            hits.append(
                DecisionHit(
                    decision_id="D8",
                    relevance="Lookup/Copy stage pattern should preserve entity load-type semantics (TRUNCATE vs FULL).",
                )
            )
            hits.append(
                DecisionHit(
                    decision_id="D9",
                    relevance="Standard stage loads default retry_count=1 and timeout=10 minutes.",
                )
            )
        return hits


def assess_adf_pipeline(path: str | Path) -> MigrationAssessment:
    return ModernizationAssessor().assess_file(path)
