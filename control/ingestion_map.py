"""Map IngestionSpec <-> warehouse_stage.control.stage_load_config (D8/D9/D10).

Decision: reuse existing control tables. No parallel control database.
"""

from __future__ import annotations

from control.models import ControlPlaneDecision, LoadType, RunGroup, StageLoadConfig
from forge.metadata.ingestion import IngestionLoadType, IngestionSpec, RetryPolicy

_LOAD_TO_CONTROL: dict[IngestionLoadType, LoadType] = {
    IngestionLoadType.FULL: LoadType.FULL,
    IngestionLoadType.TRUNCATE_AND_LOAD: LoadType.TRUNCATE_LOAD,
    IngestionLoadType.INCREMENTAL: LoadType.INCREMENTAL,
    IngestionLoadType.CDC: LoadType.INCREMENTAL,
    IngestionLoadType.SNAPSHOT: LoadType.FULL,
    IngestionLoadType.FILE: LoadType.FULL,
    IngestionLoadType.API: LoadType.FULL,
    IngestionLoadType.EVENT: LoadType.INCREMENTAL,
    IngestionLoadType.WEB: LoadType.FULL,
}

_CONTROL_TO_LOAD: dict[LoadType, IngestionLoadType] = {
    LoadType.FULL: IngestionLoadType.FULL,
    LoadType.TRUNCATE_LOAD: IngestionLoadType.TRUNCATE_AND_LOAD,
    LoadType.INCREMENTAL: IngestionLoadType.INCREMENTAL,
    LoadType.AUTO: IngestionLoadType.INCREMENTAL,
}


def control_plane_decision() -> ControlPlaneDecision:
    return ControlPlaneDecision(
        store="warehouse_stage.control",
        parallel_database_allowed=False,
        rationale=(
            "Map IngestionSpec onto existing warehouse_stage.control tables. "
            "Do not create a second control database without a demonstrated gap."
        ),
        evidence=[
            "control/models.py:StageLoadConfig",
            "foundation/metadata/ingestion.py:IngestionSpec",
            "D8/D9/D10 binding decisions",
        ],
    )


def ingestion_spec_to_stage_load_config(
    spec: IngestionSpec,
    *,
    shape: str = "det",
    run_wave: int = 1,
    run_group: RunGroup = RunGroup.STANDARD,
) -> StageLoadConfig:
    schema = (
        spec.target_schema.value
        if hasattr(spec.target_schema, "value")
        else str(spec.target_schema)
    )
    return StageLoadConfig(
        target_name=spec.target_table,
        current_name=spec.source_object,
        schema_name=schema if schema != "raw" else "stage",
        shape=shape,
        proc_name_current=f"usp_load_{spec.target_table}_current",
        proc_name_target=f"usp_load_{spec.target_table}",
        default_load_type=_LOAD_TO_CONTROL.get(spec.load_type, LoadType.FULL),
        watermark_source=spec.watermark.field_name if spec.watermark else None,
        run_group=run_group,
        run_wave=run_wave,
        timeout_minutes=spec.retry.timeout_minutes,
        retry_count=spec.retry.retry_count,
        is_active=True,
        notes=spec.notes or f"Mapped from IngestionSpec {spec.spec_id}",
    )


def stage_load_config_to_ingestion_spec(
    row: StageLoadConfig,
    *,
    spec_id: str | None = None,
    source_system: str = "legacy",
) -> IngestionSpec:
    return IngestionSpec(
        spec_id=spec_id or f"ingest_{row.target_name}",
        source_system=source_system,
        source_object=row.current_name,
        target_workspace="Foundation Development",
        target_lakehouse_or_warehouse="warehouse_stage",
        target_schema=row.schema_name,
        target_table=row.target_name,
        load_type=_CONTROL_TO_LOAD[row.default_load_type],
        watermark=None,
        retry=RetryPolicy(retry_count=row.retry_count, timeout_minutes=row.timeout_minutes),
        schedule_enabled=False,
        notes=row.notes or "",
    )
