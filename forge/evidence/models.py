"""Evidence records with Confirmed / Inferred / Unknown labels."""

from __future__ import annotations

from datetime import UTC, datetime
from typing import Any
from uuid import uuid4

from pydantic import BaseModel, Field

from forge.core.models import EvidenceStatus


def utc_now() -> datetime:
    return datetime.now(UTC)


class EvidenceRecord(BaseModel):
    evidence_id: str = Field(default_factory=lambda: str(uuid4()))
    status: EvidenceStatus
    source: str
    summary: str
    details: dict[str, Any] = Field(default_factory=dict)
    recorded_at: datetime = Field(default_factory=utc_now)
    related_assets: list[str] = Field(default_factory=list)
