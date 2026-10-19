# Access and tooling gaps found during discovery

**Date:** 2026-10-16

| Gap | Status | Impact | Next action |
|---|---|---|---|
| Key Vault `gb-fabric-keyvault` secret list | **Forbidden** (RBAC) | Cannot inventory credential topology via `az` | Request Key Vault Secrets User (or list-only) for platform engineers; or document secret owners |
| On-prem SQL MCP `user-gbp-onprem-sql-readonly` | **Error** (discovery failed) | Encompass / on-prem sources dark (D3) | Fix MCP server connection or document alternate read path |
| Git SSH to `ssh.dev.azure.com` | **Permission denied** (publickey) | Agents must use HTTPS + `az` token for push | Register SSH key in ADO or standardize HTTPS+az |
| Foundation 2.0 ADO pipelines | **None** | No CI on the new repo | Add CI from `.azuredevops/pipelines` when ready |
| Fabric Data Agent D16 item | **Not listed** in FD `fab ls` | May be renamed, removed, or not visible as that type | Re-check Fabric portal for `data_agent_operations_customer_survey` |
| Row-level SQL profiling | **Not run** this pass | No freshness/volume confirmation beyond D5 historical claim | Run read-only warehouse queries next |

## What worked (Confirmed)

- `fab auth login` session active
- `fab ls` across workspaces
- Azure MCP subscription + RG + capacity show
- ADO MCP projects / repos / pipeline list
- Local Foundation 2.0 `foundation doctor` / unit tests / factory demo
