"""ADF pipeline JSON parser producing a versioned canonical IR."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from pydantic import BaseModel, Field

from forge.core.models import EvidenceStatus
from forge.dependency_graph.graph import DependencyRelation, RelationType


class CanonicalActivity(BaseModel):
    name: str
    activity_type: str
    depends_on: list[str] = Field(default_factory=list)
    inputs: list[str] = Field(default_factory=list)
    outputs: list[str] = Field(default_factory=list)
    retry: int | None = None
    timeout: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class CanonicalPipelineIR(BaseModel):
    ir_version: str = "1.0.0"
    asset_identity: str
    source_platform: str = "AzureDataFactory"
    source_definition_path: str | None = None
    pipeline_name: str
    parameters: dict[str, Any] = Field(default_factory=dict)
    variables: dict[str, Any] = Field(default_factory=dict)
    activities: list[CanonicalActivity] = Field(default_factory=list)
    input_dependencies: list[str] = Field(default_factory=list)
    output_dependencies: list[str] = Field(default_factory=list)
    scheduling_semantics: dict[str, Any] = Field(default_factory=dict)
    retry_and_failure_policy: dict[str, Any] = Field(default_factory=dict)
    target_recommendations: list[str] = Field(default_factory=list)
    compatibility_findings: list[str] = Field(default_factory=list)
    validation_requirements: list[str] = Field(default_factory=list)
    evidence_status: EvidenceStatus = EvidenceStatus.CONFIRMED
    evidence_references: list[str] = Field(default_factory=list)


class AdfPipelineParser:
    """Parse ADF pipeline ARM/JSON definitions into CanonicalPipelineIR."""

    def parse_file(self, path: str | Path) -> CanonicalPipelineIR:
        payload = json.loads(Path(path).read_text())
        return self.parse_dict(payload, source_path=str(path))

    def parse_dict(self, payload: dict[str, Any], *, source_path: str | None = None) -> CanonicalPipelineIR:
        name = (
            payload.get("name")
            or payload.get("properties", {}).get("folder", {}).get("name")
            or "unknown_pipeline"
        )
        props = payload.get("properties") or payload
        activities_raw = props.get("activities") or []
        activities: list[CanonicalActivity] = []
        inputs: list[str] = []
        outputs: list[str] = []

        for activity in activities_raw:
            deps = [
                dep.get("activity")
                for dep in (activity.get("dependsOn") or [])
                if isinstance(dep, dict) and dep.get("activity")
            ]
            type_props = activity.get("typeProperties") or {}
            act_inputs = _collect_dataset_refs(activity.get("inputs"))
            act_outputs = _collect_dataset_refs(activity.get("outputs"))
            # Nested ExecutePipeline references.
            if activity.get("type") == "ExecutePipeline":
                ref = (type_props.get("pipeline") or {}).get("referenceName")
                if ref:
                    act_outputs.append(f"pipeline:{ref}")
            inputs.extend(act_inputs)
            outputs.extend(act_outputs)
            policy = activity.get("policy") or {}
            activities.append(
                CanonicalActivity(
                    name=str(activity.get("name") or "unnamed"),
                    activity_type=str(activity.get("type") or "Unknown"),
                    depends_on=[str(d) for d in deps],
                    inputs=act_inputs,
                    outputs=act_outputs,
                    retry=policy.get("retry"),
                    timeout=policy.get("timeout"),
                    metadata={"typeProperties_keys": sorted(type_props.keys())},
                )
            )

        findings = self._compatibility_findings(activities)
        return CanonicalPipelineIR(
            asset_identity=f"adf:{name}",
            source_definition_path=source_path,
            pipeline_name=str(name),
            parameters=props.get("parameters") or {},
            variables=props.get("variables") or {},
            activities=activities,
            input_dependencies=sorted(set(inputs)),
            output_dependencies=sorted(set(outputs)),
            retry_and_failure_policy={"activity_policies_observed": True},
            target_recommendations=["Name the orchestrator on the ground. Do not assume a vendor."],
            compatibility_findings=findings,
            validation_requirements=[
                "Do not auto-convert unsupported ADF behavior without compatibility evidence.",
                "Require behavioral comparison before cutover (D12).",
            ],
            evidence_references=[source_path] if source_path else [],
        )

    def extract_dependency_relations(self, ir: CanonicalPipelineIR) -> list[DependencyRelation]:
        relations: list[DependencyRelation] = []
        pipeline_node = ir.asset_identity
        for dep in ir.input_dependencies:
            relations.append(
                DependencyRelation(
                    source=pipeline_node,
                    destination=dep,
                    relationship_type=RelationType.READS_FROM,
                    evidence=ir.source_definition_path or ir.asset_identity,
                    evidence_status=EvidenceStatus.CONFIRMED,
                    source_version=ir.ir_version,
                )
            )
        for dep in ir.output_dependencies:
            relations.append(
                DependencyRelation(
                    source=pipeline_node,
                    destination=dep,
                    relationship_type=RelationType.WRITES_TO,
                    evidence=ir.source_definition_path or ir.asset_identity,
                    evidence_status=EvidenceStatus.CONFIRMED,
                    source_version=ir.ir_version,
                )
            )
        for activity in ir.activities:
            for parent in activity.depends_on:
                relations.append(
                    DependencyRelation(
                        source=f"{pipeline_node}/activity:{activity.name}",
                        destination=f"{pipeline_node}/activity:{parent}",
                        relationship_type=RelationType.DEPENDS_ON,
                        evidence=ir.source_definition_path or ir.asset_identity,
                        evidence_status=EvidenceStatus.CONFIRMED,
                        source_version=ir.ir_version,
                    )
                )
        return relations

    @staticmethod
    def _compatibility_findings(activities: list[CanonicalActivity]) -> list[str]:
        findings: list[str] = []
        unsupportedish = {"DatabricksNotebook", "HDInsight", "WebActivity", "AzureFunctionActivity"}
        for activity in activities:
            if activity.activity_type in unsupportedish:
                findings.append(
                    f"Activity `{activity.name}` type `{activity.activity_type}` needs an explicit compatibility check for the chosen tool."
                )
        return findings


def _collect_dataset_refs(nodes: Any) -> list[str]:
    refs: list[str] = []
    if not nodes:
        return refs
    for node in nodes:
        if not isinstance(node, dict):
            continue
        ref = node.get("referenceName") or (node.get("dataset") or {}).get("referenceName")
        if ref:
            refs.append(f"dataset:{ref}")
    return refs
