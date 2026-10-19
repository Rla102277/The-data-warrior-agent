"""Telemetry helpers (no exporters activated on import)."""

from __future__ import annotations

import logging
import uuid


def get_logger(name: str = "foundation") -> logging.Logger:
    return logging.getLogger(name)


def new_correlation_id() -> str:
    return str(uuid.uuid4())
