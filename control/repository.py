"""Repositories for control metadata.

Default implementation is in-memory / seed-file based so imports never hit Fabric.
"""

from __future__ import annotations

import re
from pathlib import Path

from control.models import ControlPlaneDecision, LoadType, RunGroup, StageLoadConfig
from forge.exceptions import ValidationError


class StageLoadConfigRepository:
    def __init__(self) -> None:
        self._rows: dict[str, StageLoadConfig] = {}

    def upsert(self, row: StageLoadConfig) -> None:
        self._rows[row.target_name] = row

    def get(self, target_name: str) -> StageLoadConfig | None:
        return self._rows.get(target_name)

    def list_active(self, *, run_group: RunGroup | None = None) -> list[StageLoadConfig]:
        rows = [row for row in self._rows.values() if row.is_active]
        if run_group is not None:
            rows = [row for row in rows if row.run_group == run_group]
        return sorted(rows, key=lambda item: (item.run_group.value, item.run_wave, item.target_name))

    def waves(self, *, run_group: RunGroup = RunGroup.STANDARD) -> dict[int, list[str]]:
        grouped: dict[int, list[str]] = {}
        for row in self.list_active(run_group=run_group):
            grouped.setdefault(row.run_wave, []).append(row.target_name)
        return {wave: sorted(names) for wave, names in sorted(grouped.items())}

    def validate_d8_d9(self) -> list[str]:
        problems: list[str] = []
        sale = self.get("sale_transfer")
        if sale and sale.default_load_type != LoadType.TRUNCATE_LOAD:
            problems.append("sale_transfer must remain TRUNCATE_LOAD (D8)")
        fiscal = self.get("fiscal_period")
        if fiscal and fiscal.default_load_type != LoadType.FULL:
            problems.append("fiscal_period must remain FULL (D8)")
        for row in self._rows.values():
            if row.retry_count != 1 and row.is_active and row.run_group == RunGroup.STANDARD:
                # D9 documents standard entities; allow documented exceptions via notes.
                if not (row.notes and "retry" in row.notes.lower()):
                    problems.append(f"{row.target_name}: standard retry_count should be 1 (D9)")
            if row.timeout_minutes != 10 and row.is_active and row.run_group == RunGroup.STANDARD:
                if not (row.notes and "timeout" in row.notes.lower()):
                    problems.append(f"{row.target_name}: standard timeout_minutes should be 10 (D9)")
        return problems


_VALUE_ROW_RE = re.compile(
    r"\(\s*'([^']*)'\s*,\s*'([^']*)'\s*,\s*'([^']*)'\s*,\s*'([^']*)'\s*,\s*'([^']*)'\s*,\s*'([^']*)'\s*,\s*'([^']*)'\s*,\s*(NULL|'[^']*')\s*,\s*'([^']*)'\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*,\s*(NULL|'[^']*')\s*\)",
    re.IGNORECASE,
)


def load_stage_load_config_from_sql(path: str | Path) -> StageLoadConfigRepository:
    """Parse INSERT rows from automation/sql/stage_load_config.sql."""
    text = Path(path).read_text()
    repo = StageLoadConfigRepository()
    matches = list(_VALUE_ROW_RE.finditer(text))
    if not matches:
        raise ValidationError(f"No stage_load_config seed rows parsed from {path}")
    for match in matches:
        watermark = match.group(8)
        notes = match.group(14)
        repo.upsert(
            StageLoadConfig(
                target_name=match.group(1),
                current_name=match.group(2),
                schema_name=match.group(3),
                shape=match.group(4),
                proc_name_current=match.group(5),
                proc_name_target=match.group(6),
                default_load_type=LoadType(match.group(7)),
                watermark_source=None if watermark.upper() == "NULL" else watermark.strip("'"),
                run_group=RunGroup(match.group(9)),
                run_wave=int(match.group(10)),
                timeout_minutes=int(match.group(11)),
                retry_count=int(match.group(12)),
                is_active=bool(int(match.group(13))),
                notes=None if notes.upper() == "NULL" else notes.strip("'"),
            )
        )
    return repo


def control_plane_decision() -> ControlPlaneDecision:
    return ControlPlaneDecision()
