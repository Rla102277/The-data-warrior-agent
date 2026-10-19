"""CLI smoke tests for implemented commands."""

from __future__ import annotations

from pathlib import Path

from forge.cli.main import main

ROOT = Path(__file__).resolve().parents[2]


def test_doctor_exits_zero() -> None:
    assert main(["doctor"]) == 0


def test_policy_denies_prod_mutation() -> None:
    code = main(
        [
            "policy",
            "--actor",
            "engineer",
            "--action",
            "update_item",
            "--workspace",
            "Foundation",
            "--name",
            "pipeline_salesforce_ingest",
            "--environment",
            "foundation",
        ]
    )
    assert code == 2


def test_validate_ingestion_spec() -> None:
    code = main(["validate", str(ROOT / "tests/fixtures/ingestion/sale_transfer.json")])
    assert code == 0


def test_lineage_from_adf_fixture() -> None:
    code = main(["lineage", "--adf", str(ROOT / "tests/fixtures/adf/sample_pipeline.json")])
    assert code == 0


def test_dbt_discover_cli() -> None:
    code = main(
        [
            "dbt",
            "discover",
            "--manifest",
            str(ROOT / "tests/fixtures/dbt/sample_manifest.json"),
        ]
    )
    assert code == 0


def test_agent_start_cli(tmp_path) -> None:
    code = main(
        [
            "agent",
            "start",
            "--title",
            "Test workflow",
            "--state-dir",
            str(tmp_path),
        ]
    )
    assert code == 0


def test_modernize_cli() -> None:
    code = main(["modernize", "--adf", str(ROOT / "tests/fixtures/adf/sample_pipeline.json")])
    assert code == 0


def test_factory_create_and_list(tmp_path) -> None:
    jobs_dir = str(tmp_path / "jobs")
    assert main(["job", "create", "--title", "cli job", "--jobs-dir", jobs_dir]) == 0
    assert main(["job", "list", "--jobs-dir", jobs_dir]) == 0


def test_factory_approve_and_rework(tmp_path) -> None:
    from forge.line import JobStore, WorkflowEngine

    jobs_dir = tmp_path / "jobs"
    engine = WorkflowEngine(JobStore(jobs_dir))
    job = engine.create_job("approve cli")
    job = engine.advance_happy_path(job)
    assert (
        main(
            [
                "job",
                "approve",
                "--job-id",
                job.job_id,
                "--jobs-dir",
                str(jobs_dir),
                "--authorized",
            ]
        )
        == 0
    )
    job2 = engine.create_job("rework cli")
    job2 = engine.advance_happy_path(job2)
    assert (
        main(
            [
                "job",
                "rework",
                "--job-id",
                job2.job_id,
                "--jobs-dir",
                str(jobs_dir),
                "--note",
                "fix D13 name",
            ]
        )
        == 0
    )


def test_doctor_reports_factory() -> None:
    # doctor prints JSON to stdout; exit code is the contract
    assert main(["doctor"]) == 0
