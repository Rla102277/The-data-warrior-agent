from engineering.reconciliation import ReconciliationEngine
from engineering.reconciliation.engine import ReconciliationStatus


def test_row_count_and_hash_reconciliation() -> None:
    engine = ReconciliationEngine()
    match = engine.compare_row_counts(100, 100)
    assert match.status == ReconciliationStatus.MATCH
    mismatch = engine.compare_row_counts(100, 90)
    assert mismatch.status == ReconciliationStatus.MISMATCH
    hashed = engine.compare_hashes("aaa", "aaa")
    assert hashed.status == ReconciliationStatus.MATCH
