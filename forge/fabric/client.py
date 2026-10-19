"""Fabric read client abstractions.

Importing this module never authenticates. Live calls require an injected
credential provider. Prefer mock/fixture clients in tests.
"""

from __future__ import annotations

from typing import Any, Protocol

import httpx

from forge.exceptions import DiscoveryError


class TokenProvider(Protocol):
    def get_token(self) -> str: ...


class FabricRestClient:
    """Minimal read-only Fabric REST client with dependency-injected auth."""

    def __init__(
        self,
        *,
        token_provider: TokenProvider,
        base_url: str = "https://api.fabric.microsoft.com/v1",
        transport: httpx.BaseTransport | None = None,
    ) -> None:
        self.token_provider = token_provider
        self.base_url = base_url.rstrip("/")
        self._client = httpx.Client(base_url=self.base_url, transport=transport, timeout=30.0)

    def close(self) -> None:
        self._client.close()

    def _headers(self) -> dict[str, str]:
        return {"Authorization": f"Bearer {self.token_provider.get_token()}"}

    def list_workspaces(self) -> list[dict[str, Any]]:
        return self._paginate("/workspaces")

    def list_items(self, workspace_id: str) -> list[dict[str, Any]]:
        return self._paginate(f"/workspaces/{workspace_id}/items")

    def _paginate(self, path: str) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        continuation: str | None = None
        while True:
            params = {"continuationToken": continuation} if continuation else None
            response = self._client.get(path, headers=self._headers(), params=params)
            if response.status_code == 429:
                raise DiscoveryError("Fabric API throttled (HTTP 429); stop and honor Retry-After.")
            if response.status_code >= 400:
                raise DiscoveryError(f"Fabric API error {response.status_code}: {response.text[:200]}")
            payload = response.json()
            batch = payload.get("value") or payload.get("workspaces") or payload.get("items") or []
            items.extend(batch)
            continuation = payload.get("continuationToken")
            if not continuation:
                break
        return items


class StaticTokenProvider:
    def __init__(self, token: str) -> None:
        self._token = token

    def get_token(self) -> str:
        return self._token


class MockFabricRestClient:
    """In-memory Fabric client for offline tests (same surface as FabricRestClient)."""

    def __init__(self, workspaces: list[dict[str, Any]], items_by_workspace: dict[str, list[dict[str, Any]]]) -> None:
        self._workspaces = workspaces
        self._items = items_by_workspace

    def list_workspaces(self) -> list[dict[str, Any]]:
        return list(self._workspaces)

    def list_items(self, workspace_id: str) -> list[dict[str, Any]]:
        if workspace_id not in self._items:
            raise DiscoveryError(f"workspace inaccessible: {workspace_id}")
        return list(self._items[workspace_id])
