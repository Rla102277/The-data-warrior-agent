"""Full-volume oriented reconciliation comparisons on provided metrics."""

from __future__ import annotations

from enum import Enum
from typing import Any

from pydantic import BaseModel, Field


class ReconciliationStatus(str, Enum):
    MATCH = "MATCH"
    TOLERANCE_MATCH = "TOLERANCE_MATCH"
    MISMATCH = "MISMATCH"


class ReconciliationResult(BaseModel):
    check_name: str
    status: ReconciliationStatus
    message: str
    metrics: dict[str, Any] = Field(default_factory=dict)


class ReconciliationEngine:
    def compare_row_counts(
        self,
        source_count: int,
        target_count: int,
        *,
        absolute_tolerance: int = 0,
    ) -> ReconciliationResult:
        delta = abs(source_count - target_count)
        if delta == 0:
            status = ReconciliationStatus.MATCH
        elif delta <= absolute_tolerance:
            status = ReconciliationStatus.TOLERANCE_MATCH
        else:
            status = ReconciliationStatus.MISMATCH
        return ReconciliationResult(
            check_name="row_count",
            status=status,
            message=f"source={source_count} target={target_count} delta={delta}",
            metrics={
                "source_count": source_count,
                "target_count": target_count,
                "delta": delta,
                "absolute_tolerance": absolute_tolerance,
            },
        )

    def compare_hashes(self, source_hash: str, target_hash: str) -> ReconciliationResult:
        matched = source_hash == target_hash
        return ReconciliationResult(
            check_name="hash",
            status=ReconciliationStatus.MATCH if matched else ReconciliationStatus.MISMATCH,
            message="hashes equal" if matched else "hashes differ",
            metrics={"source_hash": source_hash, "target_hash": target_hash},
        )
