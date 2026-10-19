# Identity for Foundation automation

**Updated:** 2026-08-17

## Workspace identities (done)

Both workspaces now have a provisioned Fabric workspace identity (no
personal OAuth for workspace-scoped operations that support WI):

| Workspace | Application ID | Service principal object ID |
|---|---|---|
| Foundation Development | `4479910e-ec55-4c17-bc53-86527c4d8550` | `9fe27e57-48e1-4927-b121-a4cb9cc37c16` |
| Foundation | `339917e0-acab-4440-bc22-c7f86f57ef43` | `0e71efc9-ecd5-4f21-a28f-1f6af3e2602a` |
| Foundation Governance | `61bce30c-4ce9-4283-93e9-add6d0c4323f` | `a8b0e71e-4b2d-44f6-8b7d-a6a1469b036a` |

FD already had one; Foundation's was provisioned 2026-08-11 via
`POST /v1/workspaces/{id}/provisionIdentity`. Foundation Governance's was
provisioned 2026-08-20 at workspace create.

All three WIs are members of Entra group
`GB Fabric API Users - Workspace Identities`
(`85f950dd-fc6f-4c46-8120-ae947551ec7e`).

## Key Vault access for Zonda (blocked 2026-08-11; retried 2026-08-17, still blocked)

Zonda notebooks read `zonda-*` secrets from `gb-fabric-keyvault`
(rg `rg-gbpartner-fabric`, RBAC enabled). The web-scrape spike reads
`firecrawl-api-key` from the same vault. FD WI needs **Key Vault Secrets User**.

Attempted as `rarchambault@greenbrickpartners.com`:
`AuthorizationFailed` on `Microsoft.Authorization/roleAssignments/write`.
Only `randerson@greenbrickpartners.com` is Owner / Key Vault Administrator on
the vault.

Retried 2026-08-17 as `rarchambault` (member of GB Fabric Administrators):
still `AuthorizationFailed` on `roleAssignments/write`. Vault RBAC shows
Owner / Key Vault Administrator = `randerson@greenbrickpartners.com` only.
GB Fabric Administrators already have Key Vault Secrets User; the WI group
does not.

Run as Randy (grant the WI group so FD + Foundation both work). Does not
need Entra app create:

```bash
bash automation/grant_wi_rbac.sh
```

## Cross-workspace service principal (blocked; runbook ready)

Creating `foundation-fabric-automation` via `az ad app create` failed with
**Insufficient privileges** (directory permission to register applications).
Needs an Entra ID admin.

**Admin path (one script):**

```bash
# Requires Application Administrator + Key Vault Admin
bash automation/provision_foundation_sp.sh
```

That script will:

1. Create/reuse app registration `foundation-fabric-automation`
2. Create SP + client secret
3. Store secret as `foundation-fabric-automation-secret` in `gb-fabric-keyvault`
4. Grant WI group Key Vault Secrets User (Zonda)
5. Assign SP Contributor on Foundation Development and Foundation

Then manually:

1. Add appId to tenant ServicePrincipal Fabric API security groups if needed
2. Create SP-backed Fabric connections (warehouse SQL, Salesforce UAT)
3. Rebind pipeline connections away from personal OAuth
4. Smoke metadata-only `SELECT 1` via `pipeline_sql_runner`

## Semantic model cloud connections (done 2026-08-12)

| Workspace | Model | Connection |
|---|---|---|
| FD | `semantic_model_finance_executive_dashboard` | **Foundation Development Lake Analytics** `8edf1d35-d1fc-4bd8-8c69-700ef02b5859` (WorkspaceIdentity) on FD host / `lake_house_analytics`. Created 2026-08-19 after the D15 rename; old **Foundation Development Lake** `86e291b0-…` still points at `lake_house_operations_analytics`. |
| FD | CustSat + other Finance SMs | Still on Foundation Development Lake `86e291b0-…` (+ FD dataverse for CustSat) until rebound to `8edf1d35-…` |
| Foundation | 4 Finance SMs | Foundation Lake `73fac61d-…` (path still `lake_house_operations_analytics` until that twin connection is retargeted) |
| Foundation | CustSat | Foundation Lake + **Foundation dataverse_gbpdev** `8e7c07b9-…` (created + host rewrite 2026-08-12) |

## ADLS for Salesforce CSV export (2026-08-12)

Created ShareableCloud connection **Foundation ADLS gbpintegrationfiles**
(`ef7726de-204a-4c49-bbbf-2f155fb939be`, WorkspaceIdentity) and rebound
`pipeline_salesforce_views_to_csv` off personal `ADLS kradhakrishnan`.

Runtime writes still need storage RBAC. Retried 2026-08-17: same
`AuthorizationFailed` on `roleAssignments/write`. Included in
`automation/grant_wi_rbac.sh` (Randy).

## Related

- Alerting (D6): placeholder DL `foundation_data_monitoring@greenbrickpartners.com`.
  Activators live in FD and Foundation (2026-08-12).
- ADO git: see [`ado-git.md`](ado-git.md). Org is `grbk`, project Fabric,
  zero repos. CreateRepository still TF401027 for current operator;
  Randall Anderson is Fabric Team admin.
- Hydration: see [`hydration-runbook.md`](hydration-runbook.md) (GATED).
- Catalog / Purview: see [`purview-catalog.md`](purview-catalog.md) (plan only; no account yet).
- Paginated export API (OBO, no SP secret): see
  [`paginated-export-api.md`](paginated-export-api.md). Entra app
  `foundation-paginated-export` via
  `automation/paginated_export_api/provision_entra_app.sh`.
