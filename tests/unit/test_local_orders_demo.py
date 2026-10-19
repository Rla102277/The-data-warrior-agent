"""M8 local synthetic demo tests."""

from __future__ import annotations

from demos.local_orders.run_demo import run


def test_local_orders_demo_passes_independent_reconciliation() -> None:
    result = run()
    assert result["status"] == "passed"
    assert result["analytics"]["order_count"] == 12
    assert result["analytics"]["gross_revenue"] == 1250.5
    assert result["quarantine_count"] == 2
    assert result["reconciliation"]["outcome"] == "PASS"
