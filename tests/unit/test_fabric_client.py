from __future__ import annotations

import httpx

from forge.discovery.fabric_adapter import InjectedFabricDiscoveryAdapter
from forge.fabric.client import FabricRestClient, MockFabricRestClient, StaticTokenProvider


def test_mock_fabric_rest_client_discovery() -> None:
    client = MockFabricRestClient(
        workspaces=[{"id": "ws-1", "name": "Foundation Development"}],
        items_by_workspace={
            "ws-1": [
                {
                    "id": "i1",
                    "displayName": "lake_house_analytics",
                    "type": "Lakehouse",
                }
            ]
        },
    )
    inventory = InjectedFabricDiscoveryAdapter(client, tenant_id="tenant-x").discover()
    assert len(inventory.assets) == 1
    assert inventory.assets[0].item_name == "lake_house_analytics"
    assert inventory.assets[0].evidence_confidence.value == "CONFIRMED"


def test_fabric_rest_client_pagination_with_httpx_mock() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        if request.url.path.endswith("/workspaces"):
            token = request.url.params.get("continuationToken")
            if not token:
                return httpx.Response(
                    200,
                    json={
                        "value": [{"id": "ws-1", "name": "Foundation Development"}],
                        "continuationToken": "page2",
                    },
                )
            return httpx.Response(
                200,
                json={"value": [{"id": "ws-2", "name": "Foundation Governance"}]},
            )
        return httpx.Response(404, json={"error": "not found"})

    transport = httpx.MockTransport(handler)
    client = FabricRestClient(token_provider=StaticTokenProvider("tok"), transport=transport)
    workspaces = client.list_workspaces()
    client.close()
    assert len(workspaces) == 2
    assert workspaces[1]["name"] == "Foundation Governance"


def test_inaccessible_workspace_marked_not_deleted() -> None:
    class PartialClient:
        def list_workspaces(self):
            return [{"id": "ws-ok", "name": "Foundation Development"}, {"id": "ws-bad", "name": "Operations"}]

        def list_items(self, workspace_id: str):
            if workspace_id == "ws-bad":
                raise RuntimeError("forbidden")
            return [{"id": "i1", "displayName": "warehouse_stage", "type": "Warehouse"}]

    inventory = InjectedFabricDiscoveryAdapter(PartialClient()).discover()
    accessible = [a for a in inventory.assets if a.accessible]
    inaccessible = [a for a in inventory.assets if not a.accessible]
    assert len(accessible) == 1
    assert len(inaccessible) == 1
    assert inaccessible[0].item_name == "__workspace_inaccessible__"
