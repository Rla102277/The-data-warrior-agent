"""M7 MCP gateway tests."""

from __future__ import annotations

from mcp.gateway import McpGateway


def test_health_reports_configured_not_live() -> None:
    health = McpGateway().health()
    assert health["gateway"] == "forge-mcp"
    assert health["servers"]
    assert all(s["live_probe"] == "NOT_RUN" for s in health["servers"])


def test_mutation_denied_for_disallowed_role() -> None:
    result = McpGateway().authorize_tool(
        server_id="azure-devops-mcp",
        agent_role="discovery",
        action="update_item",
        target={"workspace": "Forge Development", "name": "orders_daily"},
    )
    assert result["allowed"] is False


def test_unregistered_vendor_server_is_denied() -> None:
    result = McpGateway().authorize_tool(
        server_id="microsoft-fabric-cli",
        agent_role="builder",
        action="update_item",
        target={"name": "orders_daily"},
    )
    assert result["allowed"] is False
    assert "not in registry" in result["reason"]
