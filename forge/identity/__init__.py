"""Identity abstractions. No authentication occurs on import."""

from __future__ import annotations

from pydantic import BaseModel


class Actor(BaseModel):
    actor_id: str
    display_name: str | None = None
    roles: list[str] = []


class AuthContext(BaseModel):
    """Injectable auth context for cloud adapters."""

    actor: Actor
    environment: str = "local"
    can_mutate_production: bool = False
