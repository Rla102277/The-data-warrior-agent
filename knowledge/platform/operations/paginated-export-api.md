# Foundation paginated export API (OBO)

Reusable Azure Function that exports **any allowlisted** Fabric paginated
report via Power BI `ExportTo`, stages the file in Blob, then uploads to the
**signed-in user's OneDrive**. User on-behalf-of only. **No service principal
client secret** for ExportTo or Graph.

Code: [`automation/paginated_export_api/`](../../automation/paginated_export_api/).

Related research: [`customer-survey-export-api-research.md`](./customer-survey-export-api-research.md).

## Decisions

| Topic | Choice |
| --- | --- |
| Auth | OBO (delegated). Function MI + Entra federated credential for confidential client assertion |
| Host | `func-foundation-paginated-export` in `rg-gbpartner-fabric` |
| Delivery | Blob container `paginated-export-staging` then Graph OneDrive |
| Reuse | Allowlist of `(workspaceId, reportId)`; CustSat is first entry only |

## API

### `POST /api/exports`

Header: `Authorization: Bearer <user access token for api://foundation-paginated-export>`.

```json
{
  "workspaceId": "40502864-6ece-49b5-807f-6f7c11d1b3e1",
  "reportId": "786df9d9-6e94-47e6-a018-29a89472aefb",
  "format": "XLSX",
  "fileName": "custsat-detail.xlsx",
  "parameterValues": [
    { "name": "OperatingUnit", "value": "Dallas" },
    { "name": "SurveyName", "value": "30 Day" }
  ],
  "oneDrive": { "folderPath": "/Foundation Exports" }
}
```

Formats (v1): `XLSX`, `CSV`, `PDF`.

Response includes `jobId`, `status` (`Succeeded` / `Failed`), and
`oneDriveWebUrl` when successful. v1 runs the job **inline** (function timeout
10 minutes) and also persists status under `jobs/{jobId}.json` in the staging
container.

### `GET /api/exports/{jobId}`

Returns persisted job JSON (Bearer required).

### `GET /api/health`

No auth required for probe.

### `GET /api/export-download?page=comments`

Browser one-click XLSX. Easy Auth signs the user in (SSO), then the Function
runs `executeQueries` and returns an Excel attachment. `page` is one of
`comments`, `responses`, `detail`, `questions`. Optional query filters:
`ou`, `survey`, `project`, `category`.

## Allowlist

[`automation/paginated_export_api/allowlist.json`](../../automation/paginated_export_api/allowlist.json).

Non-allowlisted pairs return **403**. Add new reports by editing that file and
redeploying (or mounting as app setting later).

Seeded:

| Report | Workspace | Id |
| --- | --- | --- |
| `report_operations_customer_survey_detail` | Foundation Development | `786df9d9-6e94-47e6-a018-29a89472aefb` |

## Entra setup (no SP password)

```bash
bash automation/paginated_export_api/provision_entra_app.sh
```

Then in Entra portal for `foundation-paginated-export`:

1. **API permissions (delegated):**
   - Microsoft Graph: `Files.ReadWrite`, `openid`, `profile`, `offline_access`
   - Power BI Service: `Report.Read.All`, `Dataset.Read.All` (required for executeQueries)
2. **Admin consent**
3. After Function deploy: **Certificates & secrets → Federated credentials**
   - Issuer: `https://login.microsoftonline.com/<tenantId>/v2.0`
   - Subject: Function **system-assigned managed identity** object id
   - Audience: `api://AzureADTokenExchange`
4. Function **Easy Auth** (scripted; do not rely on portal defaults alone):

```bash
export ENTRA_CLIENT_ID=09b0f0c4-61de-4d6d-b670-9484738cd86d
bash automation/paginated_export_api/configure_easy_auth.sh
```

Portal checklist if you prefer UI:

- Microsoft provider, app `foundation-paginated-export`
- **Require authentication**
- **Unauthenticated requests: redirect to login** (browser download) or
  Bearer on API POST
- **Allowed token audiences:** `api://foundation-paginated-export`
- **Login scope:** `openid profile email offline_access api://foundation-paginated-export/access_as_user`
- **Client application requirement:** allow requests from any client application
- **Excluded paths:** `/api/health`, `/api/export-ui`, `/api/export-click`
- Entra **Web** redirect:
  `https://func-foundation-paginated-export.azurewebsites.net/.auth/login/aad/callback`

OBO must use Easy Auth's `X-MS-TOKEN-AAD-ACCESS-TOKEN`, not `Authorization`.
Easy Auth overwrites `Authorization` with an App Service session token. Using
that as the user assertion fails with AADSTS50013 (signature validation,
app id all zeros). After changing login scopes, sign out once at
`/.auth/logout` so the token store gets a fresh API access token.

Do **not** use [`provision_foundation_sp.sh`](../../automation/provision_foundation_sp.sh) for this API.

## Deploy

```bash
# Run one line at a time. Do not paste <appId> angle brackets into zsh.
bash automation/paginated_export_api/provision_entra_app.sh

# Use the appId printed by the script (example value below is the live FD app):
export ENTRA_CLIENT_ID=09b0f0c4-61de-4d6d-b670-9484738cd86d
bash automation/paginated_export_api/deploy_azure.sh
```

Creates/updates storage `stfoundationexport`, Consumption Function
`func-foundation-paginated-export` (`--https-only true` for landing-zone TLS
policy), Blob Data Contributor for MI, app settings, zip deploy.

## Caller patterns

### Power Automate (user connection)

1. Trigger (manual / Power BI button / HTTP).
2. **HTTP** action against `https://func-foundation-paginated-export.azurewebsites.net/api/exports`
   with **Azure AD** auth (user) and audience `api://foundation-paginated-export`.
3. Body: CustSat workspace/report ids + optional `parameterValues`.
4. Use returned `oneDriveWebUrl` in an email or Teams message (link only; prefer
   not attaching PII-bearing files).

### CustSat detail pages

Each detail page has **Export to Excel** (one-click XLSX download via
`/api/export-download`) and **Export to OneDrive** (form + `/Foundation Exports`).

Re-wire:

```bash
python3 -u automation/wire_custsat_detail_exports.py
```

### Local smoke (dev tokens)

```bash
export ENTRA_DEV_POWERBI_TOKEN=$(az account get-access-token \
  --resource https://analysis.windows.net/powerbi/api -o tsv --query accessToken)
export ENTRA_DEV_GRAPH_TOKEN=$(az account get-access-token \
  --resource https://graph.microsoft.com -o tsv --query accessToken)
# Run Functions host with local.settings.json; POST with any Bearer placeholder
# when both ENTRA_DEV_* are set (OBO skipped).
python3 automation/paginated_export_api/smoke_local.py
```

## Permissions the user must have

- Viewer (or higher) on the Fabric workspace containing the paginated report
- Ability to render the RDL datasource (CustSat uses Lake Analytics WI bind;
  the export still runs as the user for ExportTo)
- OneDrive (business) write under `/Foundation Exports`

## Troubleshooting

### Blank screen in browser after Easy Auth

Expected if you opened `/api/exports` or the function root in a browser tab.
Easy Auth returns **401 with an empty body**; the tab looks blank.

**Sanity check:** open only the health URL:

`https://func-foundation-paginated-export.azurewebsites.net/api/health`

You should see JSON: `{"ok": true, "service": "foundation-paginated-export", ...}`.

If health is also blank or 401, Easy Auth is blocking `/api/health`. Re-run
[`configure_easy_auth.sh`](../../automation/paginated_export_api/configure_easy_auth.sh)
and confirm **Excluded paths** includes `/api/health`.

Real export calls use **POST** with `Authorization: Bearer <token>` (Power
Automate Azure AD connector or `curl`), not a browser address bar.

## Confirmed vs inferred

- Confirmed: ExportTo contract, allowlist seed, OBO + MI federation design, repo
  scaffold and deploy script; health probe works when `/api/health` is excluded
  from Easy Auth.
- Inferred until first cloud smoke: federated OBO with Function MI works in this
  tenant without a client secret; ExportTo succeeds for CustSat under user token.
