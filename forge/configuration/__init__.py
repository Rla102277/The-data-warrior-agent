"""Configuration loading (no cloud side effects on import)."""

from forge.configuration.settings import FoundationSettings, load_settings

__all__ = ["FoundationSettings", "load_settings"]
