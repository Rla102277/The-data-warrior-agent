# Customer survey paginated detail export

Foundation Development only. Companion to `report_operations_customer_survey`.

## Artifacts

| Item | Location | Id |
| --- | --- | --- |
| Paginated report | `analytics/operations` | `786df9d9-6e94-47e6-a018-29a89472aefb` |
| Interactive report Export page | `custsat_export_paginated` (display **Export**) | parent report `9fdfa39b-edbd-45f3-aee1-e69e0db479f8` |
| RDL source | `automation/rdl/report_operations_customer_survey_detail.rdl` | |
| Deploy script | `automation/build_custsat_paginated_export.py` | |

## Behavior

- Detail tablix over `lake_house_analytics.operations.customer_survey_obt` (SQLAZURE, Integrated / SSO). Buyer email and phone are not in the layout.
- RDL parameters (single-value; Fabric authoring rejects MultiValue on this workload): `OperatingUnit`, `SurveyName`, `ProjectName`, `QuestionCategory`.
- Export page primary button **Export to my OneDrive** opens the Function UI
  (`/api/export-ui`) which signs the user in and runs the OBO export API.
- **Current (2026-09-02):** detail pages use dual export buttons instead. See
  `automation/wire_custsat_detail_exports.py` and [paginated-export-api.md](./paginated-export-api.md).
- Executive Scorecard footer has **Export detail** page navigation.

Re-wire the OneDrive button after Export page rebuilds:

```bash
python3 -u automation/wire_custsat_export_api.py
```

Limitation: choose one value per filter for a precise export. Multi-select RDL parameters are not accepted by the FD paginated authoring API.

## Related

- Embed / Export To File API research: [customer-survey-export-api-research.md](./customer-survey-export-api-research.md)
- Reusable OBO export API (Blob → OneDrive): [paginated-export-api.md](./paginated-export-api.md)

## Redeploy

```bash
python3 -u automation/build_custsat_paginated_export.py
# or refresh interactive page only:
python3 -u automation/build_custsat_paginated_export.py \
  --paginated-id 786df9d9-6e94-47e6-a018-29a89472aefb \
  --skip-paginated-create
```

The script binds the RDL datasource to **Foundation Development Lake Analytics**
(`8edf1d35-…`, WorkspaceIdentity) via `Default.BindToGateway`. Without that bind,
the service keeps a PersonalCloud SQL datasource with `credentialType: NotSpecified`
and the visual fails with "Unable to render paginated report / underlying data source".

Notes:

- Create/update uses Fabric Items API. Do not set `definition.format` to `PaginatedReportDefinition` (rejected).
- MultiValue parameters with `ValidValues` dataset references are rejected by the RDL authoring workload; keep simple nullable string parameters.
- Power BI Imports API (`/imports` with `.rdl`) returns `RequestedFileIsEncryptedOrCorrupted` in this tenant; use Fabric `updateDefinition` instead.
- Workspace Identity must retain read on `lake_house_analytics` (same connection used by CustSat / Finance SMs).

## Confirmed vs inferred

- Confirmed: paginated item in FD; Export page with `paginatedReport` visual; under `analytics/operations`; datasource rebound to Lake Analytics WI (`8edf1d35-…` / gateway `80846a8f-…`).
- Inferred until UI check: Excel export from the embedded toolbar works after a browser refresh of the Export page.

## Related

- Embed / Export To File research: [customer-survey-export-api-research.md](./customer-survey-export-api-research.md)
- Reusable OBO export API (Blob → OneDrive): [paginated-export-api.md](./paginated-export-api.md)
