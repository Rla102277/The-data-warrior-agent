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
        server_id="microsoft-fabric-cli",
        agent_role="discovery",
        action="update_item",
        target={"workspace": "Foundation Development", "name": "pipeline_x"},
    )
    assert result["allowed"] is False


def test_datafactory_mcp_note_separates_classic_adf() -> None:
    server = McpGateway().get_server("microsoft-datafactory-mcp")
    assert server is not None
    note = McpGateway._notes(server)
    assert "not classic" in note.lower() or "Fabric Data Factory" in note
