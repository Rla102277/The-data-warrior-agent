"""Forge CLI entrypoint.

Implemented commands are operational. Placeholders are not exposed as ready.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any

from discovery.adf.parser import AdfPipelineParser
from discovery.dbt import DbtDiscovery
from forge import __version__
from forge.agents import AgentTaskResult, Supervisor
from forge.configuration import load_settings
from forge.dependency_graph import DependencyGraph
from forge.discovery import MockFabricDiscoveryAdapter
from forge.metadata import IngestionLoadType, IngestionSpec, RetryPolicy
from forge.policies import PolicyDecision, evaluate_action


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="forge",
        description="Forge Data and AI engineering CLI",
    )
    parser.add_argument("--version", action="version", version=f"forge {__version__}")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("doctor", help="Check local Forge SDK install and binding conventions")

    inv = sub.add_parser("inventory", help="Build inventory from Fixture discovery")
    inv.add_argument(
        "--fixture",
        default="tests/fixtures/fabric/sample_inventory.yaml",
        help="Path to Fabric inventory fixture",
    )

    disc = sub.add_parser("discover", help="Discover assets (fixture, ADF JSON, or dbt manifest)")
    disc.add_argument("--adf", help="Path to ADF pipeline JSON")
    disc.add_argument("--dbt-manifest", help="Path to dbt manifest.json")
    disc.add_argument(
        "--fabric-fixture",
        default="tests/fixtures/fabric/sample_inventory.yaml",
        help="Path to Fabric inventory fixture",
    )

    dbt = sub.add_parser("dbt", help="dbt discovery / lineage / naming validation")
    dbt.add_argument(
        "dbt_command",
        choices=["discover", "lineage", "validate"],
        help="dbt subcommand",
    )
    dbt.add_argument(
        "--manifest",
        default="dbt/target/manifest.json",
        help="Path to dbt manifest.json",
    )
    dbt.add_argument("--model", help="Model name or unique_id for lineage impact")

    agent = sub.add_parser("agent", help="Supervisor workflow start / next / record")
    agent.add_argument(
        "agent_command",
        choices=["start", "status", "next", "record"],
        help="agent subcommand",
    )
    agent.add_argument("--title", help="Workflow title for start")
    agent.add_argument("--workflow-id", help="Workflow id")
    agent.add_argument(
        "--state-dir",
        default="rebuild/execution_ledger/workflows",
        help="Persistent workflow state directory",
    )
    agent.add_argument("--result-json", help="Path to AgentTaskResult JSON for record")

    pol = sub.add_parser("policy", help="Evaluate a Forge policy action")
    pol.add_argument("--actor", required=True)
    pol.add_argument("--action", required=True)
    pol.add_argument("--workspace", default="Forge Development")
    pol.add_argument("--name", default="")
    pol.add_argument("--schema", default="")
    pol.add_argument("--item-type", default="")
    pol.add_argument("--environment", default="")
    pol.add_argument("--approval-item", default="")
    pol.add_argument("--approval-action", default="")
    pol.add_argument("--authorized", action="store_true")

    lin = sub.add_parser("lineage", help="Show dependency impact from ADF IR or dbt manifest")
    lin.add_argument("--adf", help="Path to ADF pipeline JSON")
    lin.add_argument("--dbt-manifest", help="Path to dbt manifest.json")
    lin.add_argument("--node", help="Optional node id / model name for impact analysis")

    val = sub.add_parser("validate", help="Validate an ingestion metadata spec JSON/YAML path")
    val.add_argument("path", help="Path to ingestion spec JSON")

    fac = sub.add_parser("job", help="Forge Line job runtime (Jobsite successor)")
    fac.add_argument(
        "job_command",
        choices=[
            "create",
            "list",
            "inspect",
            "resume",
            "cancel",
            "demo",
            "board",
            "assess-adf",
            "approve",
            "rework",
        ],
        help="job subcommand",
    )
    fac.add_argument("--title", help="Job title for create")
    fac.add_argument("--job-id", help="Job id")
    fac.add_argument("--jobs-dir", default="forge-line/jobs", help="Job store directory")
    fac.add_argument("--adf", default="tests/fixtures/adf/sample_pipeline.json", help="ADF JSON for assess-adf")
    fac.add_argument("--actor", default="human", help="Actor for approve/rework")
    fac.add_argument("--note", default="", help="Feedback note for rework")
    fac.add_argument(
        "--authorized",
        action="store_true",
        help="Explicit authorization flag required for approve",
    )
    fac.add_argument(
        "--deploy-production",
        action="store_true",
        help="Request production deploy (D12 policy gate; default false)",
    )
    fac.add_argument("--target-name", default="", help="Named item for production policy checks")

    mod = sub.add_parser("modernize", help="ADF modernization assessment (Milestone 2)")
    mod.add_argument("--adf", default="tests/fixtures/adf/sample_pipeline.json")

    args = parser.parse_args(argv)
    handlers = {
        "doctor": cmd_doctor,
        "inventory": cmd_inventory,
        "discover": cmd_discover,
        "dbt": cmd_dbt,
        "agent": cmd_agent,
        "policy": cmd_policy,
        "lineage": cmd_lineage,
        "validate": cmd_validate,
        "job": cmd_factory,
        "modernize": cmd_modernize,
    }
    return handlers[args.command](args)


def cmd_doctor(_: argparse.Namespace) -> int:
    from forge.jobsite_bridge import jobsite_bridge_status

    settings = load_settings()
    bridge = jobsite_bridge_status()
    factory_root = Path("forge-line")
    checks = {
        "sdk_version": __version__,
        "default_workspace": settings.default_workspace,
        "layers": ["raw", "stage", "control", "transform", "analytics"],
        "dbt_project_name": "forge",
        "shared_analytics_lakehouse": "lake_house_analytics",
        "python": sys.version.split()[0],
        "factory": "Forge Line",
        "factory_path_present": factory_root.exists(),
        "jobsite_absorption": bridge.absorption_status,
        "cli": "forge",
        "default_autonomy_level": 2,
        "default_platform_profile": "forge-default",
        "llm_required": False,
    }
    print(json.dumps({"status": "ok", "checks": checks}, indent=2))
    return 0


def cmd_inventory(args: argparse.Namespace) -> int:
    path = Path(args.fixture)
    inventory = MockFabricDiscoveryAdapter(path).discover()
    payload = {
        "inventory_id": inventory.inventory_id,
        "asset_count": len(inventory.assets),
        "assets": [asset.model_dump(mode="json") for asset in inventory.assets],
    }
    print(json.dumps(payload, indent=2, default=str))
    return 0


def cmd_discover(args: argparse.Namespace) -> int:
    result: dict[str, Any] = {}
    if args.adf:
        ir = AdfPipelineParser().parse_file(args.adf)
        result["adf"] = ir.model_dump(mode="json")
    if args.dbt_manifest:
        inventory = DbtDiscovery().discover(manifest_path=args.dbt_manifest)
        result["dbt"] = {
            "project_name": inventory.project_name,
            "model_count": inventory.model_count,
            "source_count": inventory.source_count,
            "test_count": inventory.test_count,
            "naming_violations": inventory.naming_violations,
        }
    fabric_path = Path(args.fabric_fixture)
    if fabric_path.exists():
        inventory = MockFabricDiscoveryAdapter(fabric_path).discover()
        result["fabric"] = {
            "asset_count": len(inventory.assets),
            "workspaces": sorted({a.workspace_name for a in inventory.assets}),
        }
    print(json.dumps(result, indent=2, default=str))
    return 0


def cmd_dbt(args: argparse.Namespace) -> int:
    discovery = DbtDiscovery()
    inventory = discovery.discover(manifest_path=args.manifest)
    if args.dbt_command == "discover":
        print(
            json.dumps(
                {
                    "project_name": inventory.project_name,
                    "dbt_version": inventory.dbt_version,
                    "model_count": inventory.model_count,
                    "source_count": inventory.source_count,
                    "test_count": inventory.test_count,
                    "models": [model.model_dump() for model in inventory.models],
                    "naming_violations": inventory.naming_violations,
                },
                indent=2,
            )
        )
        return 0
    if args.dbt_command == "validate":
        ok = len(inventory.naming_violations) == 0
        print(
            json.dumps(
                {
                    "valid": ok,
                    "project_name": inventory.project_name,
                    "naming_violations": inventory.naming_violations,
                },
                indent=2,
            )
        )
        return 0 if ok else 2
    if not args.model:
        print(json.dumps({"error": "--model is required for lineage"}, indent=2))
        return 2
    impact = discovery.impact(args.model, inventory)
    print(json.dumps({"model": args.model, "impact": impact}, indent=2))
    return 0


def cmd_agent(args: argparse.Namespace) -> int:
    supervisor = Supervisor(state_dir=args.state_dir)
    if args.agent_command == "start":
        if not args.title:
            print(json.dumps({"error": "--title is required for start"}, indent=2))
            return 2
        state = supervisor.start(args.title)
        print(json.dumps(state.model_dump(mode="json"), indent=2, default=str))
        return 0
    if not args.workflow_id:
        print(json.dumps({"error": "--workflow-id is required"}, indent=2))
        return 2
    state = supervisor.load(args.workflow_id)
    if args.agent_command == "status":
        print(json.dumps(state.model_dump(mode="json"), indent=2, default=str))
        return 0
    if args.agent_command == "next":
        task = supervisor.next_task(state)
        supervisor.save(state)
        print(json.dumps(task.model_dump(mode="json"), indent=2, default=str))
        return 0
    if not args.result_json:
        print(json.dumps({"error": "--result-json is required for record"}, indent=2))
        return 2
    result = AgentTaskResult.model_validate_json(Path(args.result_json).read_text())
    state = supervisor.record_result(state, result)
    print(json.dumps(state.model_dump(mode="json"), indent=2, default=str))
    return 0 if state.stage.value != "blocked" else 2


def cmd_policy(args: argparse.Namespace) -> int:
    approval = None
    if args.authorized or args.approval_item:
        approval = {
            "authorized": bool(args.authorized),
            "item": args.approval_item or args.name,
            "action": args.approval_action or args.action,
            "explicit_written_authorization": bool(args.authorized),
        }
    result = evaluate_action(
        actor=args.actor,
        action=args.action,
        target={
            "workspace": args.workspace,
            "name": args.name,
            "schema": args.schema,
            "item_type": args.item_type,
        },
        environment=args.environment or None,
        approval=approval,
    )
    print(json.dumps(result.model_dump(), indent=2))
    return 0 if result.decision == PolicyDecision.ALLOW else 2


def cmd_lineage(args: argparse.Namespace) -> int:
    if args.dbt_manifest:
        discovery = DbtDiscovery()
        inventory = discovery.discover(manifest_path=args.dbt_manifest)
        if not args.node:
            print(json.dumps({"error": "--node is required for dbt lineage"}, indent=2))
            return 2
        payload = {"model": args.node, "impact": discovery.impact(args.node, inventory)}
        print(json.dumps(payload, indent=2))
        return 0
    if not args.adf:
        print(json.dumps({"error": "provide --adf or --dbt-manifest"}, indent=2))
        return 2
    parser = AdfPipelineParser()
    ir = parser.parse_file(args.adf)
    graph = DependencyGraph()
    graph.extend(parser.extract_dependency_relations(ir))
    node = args.node or ir.asset_identity
    payload = {
        "pipeline": ir.pipeline_name,
        "node": node,
        "impact": graph.impact(node),
        "cycles": graph.cycles(),
        "relation_count": len(graph.relations()),
    }
    print(json.dumps(payload, indent=2))
    return 0


def cmd_validate(args: argparse.Namespace) -> int:
    path = Path(args.path)
    raw = json.loads(path.read_text())
    # Preserve D8/D9 defaults when omitted.
    if "retry" not in raw:
        raw["retry"] = RetryPolicy().model_dump()
    if "load_type" in raw and isinstance(raw["load_type"], str):
        raw["load_type"] = IngestionLoadType(raw["load_type"])
    spec = IngestionSpec.model_validate(raw)
    if spec.schedule_enabled:
        print(
            json.dumps(
                {
                    "valid": False,
                    "error": "schedule_enabled must remain false until authorized",
                },
                indent=2,
            )
        )
        return 2
    print(json.dumps({"valid": True, "control_row": spec.to_control_row()}, indent=2))
    return 0


def cmd_modernize(args: argparse.Namespace) -> int:
    from forge.modernization import assess_adf_pipeline

    assessment = assess_adf_pipeline(args.adf)
    print(json.dumps(assessment.model_dump(mode="json"), indent=2, default=str))
    return 0 if not assessment.cutover_allowed else 0


def cmd_factory(args: argparse.Namespace) -> int:
    from forge.line import JobStore, WorkflowEngine, WorkflowStage

    store = JobStore(args.jobs_dir)
    engine = WorkflowEngine(store)

    if args.job_command == "create":
        if not args.title:
            print(json.dumps({"error": "--title is required for create"}, indent=2))
            return 2
        job = engine.create_job(args.title)
        print(json.dumps(job.model_dump(mode="json"), indent=2, default=str))
        return 0
    if args.job_command == "list":
        jobs = [
            {
                "job_id": job.job_id,
                "title": job.title,
                "stage": job.stage.value,
                "autonomy_level": int(job.autonomy_level),
                "platform_profile": job.platform_profile,
            }
            for job in store.list_jobs()
        ]
        print(json.dumps({"jobs": jobs}, indent=2))
        return 0
    if args.job_command == "board":
        board = Path("forge-line/board.json")
        if not board.exists():
            store._rewrite_board()
        print(board.read_text() if board.exists() else json.dumps({"jobs": []}))
        return 0
    if args.job_command == "demo":
        from demos.local_orders.run_demo import run

        result = run()
        print(json.dumps(result, indent=2, default=str))
        return 0 if result.get("status") == "passed" else 2
    if args.job_command == "assess-adf":
        from forge.modernization import assess_adf_pipeline

        assessment = assess_adf_pipeline(args.adf)
        print(json.dumps(assessment.model_dump(mode="json"), indent=2, default=str))
        return 0
    if not args.job_id:
        print(json.dumps({"error": "--job-id is required"}, indent=2))
        return 2
    if args.job_command == "inspect":
        job = store.load(args.job_id)
        print(json.dumps(job.model_dump(mode="json"), indent=2, default=str))
        return 0
    if args.job_command == "resume":
        job = engine.resume(args.job_id)
        print(json.dumps(job.model_dump(mode="json"), indent=2, default=str))
        return 0
    if args.job_command == "cancel":
        job = engine.cancel(store.load(args.job_id))
        print(json.dumps(job.model_dump(mode="json"), indent=2, default=str))
        return 0
    if args.job_command == "approve":
        job = store.load(args.job_id)
        if job.stage != WorkflowStage.APPROVAL_PENDING:
            print(
                json.dumps(
                    {
                        "error": "approve requires APPROVAL_PENDING",
                        "stage": job.stage.value,
                    },
                    indent=2,
                )
            )
            return 2
        try:
            job = engine.approve(
                job,
                actor=args.actor,
                authorized=bool(args.authorized),
                deploy_production=bool(args.deploy_production),
                target_name=args.target_name or job.title,
            )
        except PermissionError as exc:
            print(json.dumps({"error": str(exc), "status": "denied"}, indent=2))
            return 2
        print(json.dumps(job.model_dump(mode="json"), indent=2, default=str))
        return 0
    if args.job_command == "rework":
        from forge.line import InvalidTransitionError

        if not args.note:
            print(json.dumps({"error": "--note is required for rework"}, indent=2))
            return 2
        job = store.load(args.job_id)
        try:
            job = engine.rework(job, note=args.note, actor=args.actor)
        except InvalidTransitionError as exc:
            print(json.dumps({"error": str(exc)}, indent=2))
            return 2
        print(json.dumps(job.model_dump(mode="json"), indent=2, default=str))
        return 0
    print(json.dumps({"error": "unknown job command"}, indent=2))
    return 2


if __name__ == "__main__":
    raise SystemExit(main())
