# Foundation agent supervisor

The supervisor is a deterministic workflow state machine.

```bash
foundation agent start --title "Discover Salesforce stage loads"
foundation agent next --workflow-id <id>
foundation agent record --workflow-id <id> --result-json ./result.json
foundation agent status --workflow-id <id>
```

Rules enforced in code:

- Agents cannot set `self_certified_production=true`.
- Ship/production actions still pass through `forge.policies.evaluate_action`.
- Attempt limits block infinite autonomous loops.
- State is persisted under `rebuild/execution_ledger/workflows/` (gitignored).

Jobsite remains the live multi-agent factory runtime. This supervisor is the Foundation SDK workflow control plane for rebuild phases and CLI-driven jobs.
