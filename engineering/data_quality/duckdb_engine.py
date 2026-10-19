"""Independent local quality engine using DuckDB when available.

Falls back to in-memory Python checks if DuckDB is not installed.
Never trusts builder-provided expected aggregates as sole proof.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

from engineering.data_quality.engine import QualityEngine, QualityOutcome, QualityResult


class DuckDbQualityEngine:
    def __init__(self) -> None:
        self._duck = None
        try:
            import duckdb  # type: ignore

            self._duck = duckdb
        except ImportError:
            self._duck = None
        self._fallback = QualityEngine()

    @property
    def duckdb_available(self) -> bool:
        return self._duck is not None

    def profile_csv(self, path: str | Path, *, sample_limit: int = 10000) -> dict[str, Any]:
        path = Path(path)
        if self._duck is None:
            # Metadata-only fallback: count lines
            lines = path.read_text().splitlines()
            return {
                "engine": "python_fallback",
                "row_count": max(0, len(lines) - 1),
                "columns": lines[0].split(",") if lines else [],
                "sample_limit": sample_limit,
            }
        con = self._duck.connect(database=":memory:")
        rel = con.execute(
            f"SELECT * FROM read_csv_auto(?, sample_size={int(sample_limit)})",
            [str(path)],
        )
        cols = [d[0] for d in rel.description]
        count = con.execute(
            f"SELECT count(*) FROM read_csv_auto(?, sample_size={int(sample_limit)})",
            [str(path)],
        ).fetchone()[0]
        nulls = {}
        for col in cols:
            nulls[col] = con.execute(
                f'SELECT sum(CASE WHEN "{col}" IS NULL THEN 1 ELSE 0 END) FROM read_csv_auto(?, sample_size={int(sample_limit)})',
                [str(path)],
            ).fetchone()[0]
        return {
            "engine": "duckdb",
            "row_count": int(count),
            "columns": cols,
            "null_counts": nulls,
            "sample_limit": sample_limit,
        }

    def reconcile_aggregates(
        self,
        *,
        actual: dict[str, float],
        expected: dict[str, float],
        tolerance: float = 0.0,
    ) -> QualityResult:
        """Compare actual vs independent expected fixtures (never self-scored)."""
        mismatches = []
        for key, exp in expected.items():
            got = float(actual.get(key, float("nan")))
            if abs(got - float(exp)) > tolerance:
                mismatches.append({"metric": key, "expected": exp, "actual": got})
        if mismatches:
            return QualityResult(
                check_name="aggregate_reconciliation",
                outcome=QualityOutcome.FAIL,
                message="Aggregate mismatch against independent fixtures",
                metrics={"mismatches": mismatches},
            )
        return QualityResult(
            check_name="aggregate_reconciliation",
            outcome=QualityOutcome.PASS,
            message="Aggregates match independent fixtures",
            metrics={"compared": list(expected.keys())},
        )

    def evaluate_context(self, check_names: list[str], context: dict[str, Any]) -> list[QualityResult]:
        return self._fallback.evaluate_many(check_names, context)
