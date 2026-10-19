"""End-to-end local-orders evidence lifecycle."""

from __future__ import annotations

from demos.local_orders.accept_lifecycle import run


def test_local_orders_acceptance_stops_for_a_human(tmp_path) -> None:
    summary = run(tmp_path / "jobs")
    assert summary["status"] == "approval_pending"
    assert summary["synthetic"] is False
    assert summary["reviews_independent"] is False
    names = [item["name"] for item in summary["commands"]]
    assert "failing-test" in names
    assert "passing-test" in names
    failing = next(item for item in summary["commands"] if item["name"] == "failing-test")
    passing = next(item for item in summary["commands"] if item["name"] == "passing-test")
    assert failing["exit_code"] == 1
    assert passing["exit_code"] == 0
    assert passing["synthetic"] is False
