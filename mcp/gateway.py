"""MCP capability gateway: allowlist + policy before mutations.

No vendor server is registered by default. Add a server only after the ground
names that tool.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any

import yaml

from forge.policies import PolicyDecision, evaluate_action


class McpGateway:
    def __init__(self, registry_path: str | Path = "mcp/registry/capability_registry.yaml") -> None:
        self.registry_path = Path(registry_path)
        self.registry = yaml.safe_load(self.registry_path.read_text()) if self.registry_path.exists() else {"servers": []}

    def servers(self) -> list[dict[str, Any]]:
        return list(self.registry.get("servers") or [])

    def get_server(self, server_id: str) -> dict[str, Any] | None:
        for server in self.servers():
            if server.get("id") == server_id:
                return server
        return None

    def health(self) -> dict[str, Any]:
        """Never fake connectivity. Report configured vs disconnected."""
        results = []
        for server in self.servers():
            results.append(
                {
                    "id": server.get("id"),
                    "status": "CONFIGURED" if server else "NOT_CONFIGURED",
                    "live_probe": "NOT_RUN",
                    "mutation_capability": bool(server.get("mutation_capability")),
                    "notes": self._notes(server),
                }
            )
        return {"gateway": "forge-mcp", "servers": results}

    @staticmethod
    def _notes(server: dict[str, Any]) -> str:
        return str(server.get("purpose") or "")

    def authorize_tool(
        self,
        *,
        server_id: str,
        agent_role: str,
        action: str,
        target: dict[str, Any] | None = None,
        approval: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        server = self.get_server(server_id)
        if server is None:
            return {"allowed": False, "reason": f"server `{server_id}` not in registry"}
        roles = server.get("allowed_agent_roles") or []
        if agent_role not in roles:
            return {"allowed": False, "reason": f"role `{agent_role}` not allowed for {server_id}"}
        if server.get("mutation_capability") and action not in {"read", "discover", "inventory", "validate"}:
            policy = evaluate_action(
                actor=f"mcp:{agent_role}",
                action=action,
                target=target or {},
                approval=approval,
            )
            return {
                "allowed": policy.decision == PolicyDecision.ALLOW,
                "policy": policy.model_dump(),
                "server_id": server_id,
            }
        return {"allowed": True, "server_id": server_id, "mode": "read_or_configured"}
