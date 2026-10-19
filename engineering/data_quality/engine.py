"""Reusable quality checks with configurable outcomes."""

from __future__ import annotations

from collections.abc import Callable
from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class QualityOutcome(str, Enum):
    PASS = "PASS"
    WARN = "WARN"
    FAIL = "FAIL"
    QUARANTINE = "QUARANTINE"
    BLOCK_PUBLICATION = "BLOCK_PUBLICATION"


class QualityResult(BaseModel):
    check_name: str
    outcome: QualityOutcome
    message: str
    metrics: dict[str, Any] = Field(default_factory=dict)


class QualityEngine:
    def __init__(self) -> None:
        self._checks: dict[str, Callable[[dict[str, Any]], QualityResult]] = {
            "schema": self._check_schema,
            "completeness": self._check_completeness,
            "uniqueness": self._check_uniqueness,
            "freshness": self._check_freshness,
            "row_count": self._check_row_count,
        }

    def evaluate(self, check_name: str, context: dict[str, Any]) -> QualityResult:
        check = self._checks.get(check_name)
        if check is None:
            return QualityResult(
                check_name=check_name,
                outcome=QualityOutcome.FAIL,
                message=f"Unknown quality check `{check_name}`.",
            )
        return check(context)

    def evaluate_many(self, check_names: list[str], context: dict[str, Any]) -> list[QualityResult]:
        return [self.evaluate(name, context) for name in check_names]

    def publication_allowed(self, results: list[QualityResult]) -> bool:
        blocking = {QualityOutcome.FAIL, QualityOutcome.QUARANTINE, QualityOutcome.BLOCK_PUBLICATION}
        return not any(result.outcome in blocking for result in results)

    @staticmethod
    def _check_schema(context: dict[str, Any]) -> QualityResult:
        expected = set(context.get("expected_columns") or [])
        actual = set(context.get("actual_columns") or [])
        missing = sorted(expected - actual)
        if missing:
            return QualityResult(
                check_name="schema",
                outcome=QualityOutcome.BLOCK_PUBLICATION,
                message=f"Missing columns: {missing}",
                metrics={"missing": missing},
            )
        return QualityResult(check_name="schema", outcome=QualityOutcome.PASS, message="Schema ok")

    @staticmethod
    def _check_completeness(context: dict[str, Any]) -> QualityResult:
        null_rate = float(context.get("null_rate", 0.0))
        threshold = float(context.get("null_threshold", 0.05))
        if null_rate > threshold:
            return QualityResult(
                check_name="completeness",
                outcome=QualityOutcome.FAIL,
                message=f"Null rate {null_rate} exceeds threshold {threshold}",
                metrics={"null_rate": null_rate, "threshold": threshold},
            )
        return QualityResult(
            check_name="completeness",
            outcome=QualityOutcome.PASS,
            message="Completeness ok",
            metrics={"null_rate": null_rate},
        )

    @staticmethod
    def _check_uniqueness(context: dict[str, Any]) -> QualityResult:
        duplicate_count = int(context.get("duplicate_count", 0))
        if duplicate_count > 0:
            return QualityResult(
                check_name="uniqueness",
                outcome=QualityOutcome.FAIL,
                message=f"Found {duplicate_count} duplicate keys",
                metrics={"duplicate_count": duplicate_count},
            )
        return QualityResult(check_name="uniqueness", outcome=QualityOutcome.PASS, message="Unique")

    @staticmethod
    def _check_freshness(context: dict[str, Any]) -> QualityResult:
        lag_minutes = float(context.get("lag_minutes", 0.0))
        sla = float(context.get("freshness_sla_minutes", 60.0))
        if lag_minutes > sla:
            return QualityResult(
                check_name="freshness",
                outcome=QualityOutcome.WARN,
                message=f"Lag {lag_minutes}m exceeds SLA {sla}m",
                metrics={"lag_minutes": lag_minutes, "sla": sla},
            )
        return QualityResult(check_name="freshness", outcome=QualityOutcome.PASS, message="Fresh")

    @staticmethod
    def _check_row_count(context: dict[str, Any]) -> QualityResult:
        actual = int(context.get("row_count", 0))
        expected_min = int(context.get("expected_min_rows", 0))
        if actual < expected_min:
            return QualityResult(
                check_name="row_count",
                outcome=QualityOutcome.QUARANTINE,
                message=f"Row count {actual} below minimum {expected_min}",
                metrics={"row_count": actual, "expected_min_rows": expected_min},
            )
        return QualityResult(
            check_name="row_count",
            outcome=QualityOutcome.PASS,
            message="Row count ok",
            metrics={"row_count": actual},
        )
