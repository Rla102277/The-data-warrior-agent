# Foundation Governance workspace

**Created:** 2026-08-20  
**Decision:** D17  
**Status:** Live. Single governance workspace for the Foundation estate.
Schedules off. Audit-Dev left intact (D12).

## Workspace

| Field | Value |
|---|---|
| Display name | `Foundation Governance` |
| ID | `c9fde10b-f6ed-4a45-a05b-9d41eb782ed8` |
| Capacity | `gbpwus3fabric01` `21c3aacf-…` (F32, West US 3) |
| Workspace identity | app `61bce30c-…` / SP `a8b0e71e-…` |
| Pair | None. This is the one governance workspace (not a Dev/Prod twin). |
| Portal | https://app.fabric.microsoft.com/groups/c9fde10b-f6ed-4a45-a05b-9d41eb782ed8 |

**What belongs here:** auditor snapshot of the Fabric estate, RBAC planning /
drift, object-dependency inventory, governance lakehouse extracts.

**What does not belong here:** Finance/operations presentation (reports, OBT
semantic models), stage orchestrators, or `pipeline_audit_cleanup` (that stays
in Foundation `utilities` as a job-log cleanup pipeline).

## Auditor path

1. Open `notebook_governance_auditor_guide` (folder `audit`).
2. Run `notebook_governance_auditor_capture` (read-only). First successful
   run: 2026-08-20 17:49-17:53 UTC, job `51ead4b7-…`.
3. Query snapshot tables in `lake_house_governance`.
4. Drill with object-dependency or RBAC drift notebooks as needed.

Do **not** run the RBAC **apply** notebooks without a change ticket. They
write DataAccessRoles and TMSL.

### Snapshot tables (confirmed present after first capture)

| Table | What an auditor gets |
|---|---|
| `governance_capture_run_sum` | One row per snapshot |
| `governance_workspace_det` | Workspaces, capacity, workspace identity |
| `governance_item_det` | Every item |
| `governance_role_assignment_det` | Workspace Admin / Member / Contributor / Viewer |
| `governance_git_det` | Git connected or NotConnected |
| `governance_job_instance_det` | Recent pipeline / notebook / semantic-model runs |
| `governance_item_connection_det` | Item to connection binding |
| `governance_activity_event_det` | Tenant activity (view / edit / refresh) |

`governance_schedule_det` and `governance_connection_det` are written when the
capture finds rows; empty results are skipped.

### What this pack still cannot prove

- Git history / PR / two-person promote (FD git is NotConnected)
- Orchestrator row-level load evidence (`control.audit_*` in `warehouse_stage`)
- Signed IPE tie-out of Finance numbers to NSE
- Capacity CU (use **Microsoft Fabric Capacity Metrics**)

## Folders and items

| Folder | Item | ID |
|---|---|---|
| `audit` | `notebook_governance_auditor_guide` | `64e2676e-06d8-40c7-9d1f-b947809f892a` |
| `audit` | `notebook_governance_auditor_capture` | `79b22617-2fd6-4e0c-8345-71fffdafba32` |
| `rbac` | `lake_house_governance` | `89181b59-3339-4c34-98cf-074c736d1a72` |
| `rbac` | `notebook_governance_rbac_audit_maintenance` | `55ffec7a-911f-4513-9407-8b045d37d9b1` |
| `rbac` | `notebook_governance_rbac_drift_detection` | `ba5330e4-9894-4764-9cc4-ca97acc0a891` |
| `rbac` | `notebook_governance_rbac_policy_lakehouse_warehouse` | `7177b4fc-29cf-4248-9b85-1faadb9c2910` |
| `rbac` | `notebook_governance_rbac_policy_semantic_models` | `68b8b6ee-7395-4c51-bbab-e96b3246a104` |
| `inventory` | `notebook_governance_object_dependency` | `06e149b8-e046-48ec-b029-e4873ea6c159` |

Local source: `automation/notebooks/notebook_governance_auditor_capture.ipynb`
and `notebook_governance_auditor_guide.py`.

## Roles (confirmed 2026-08-20)

| Principal | Role |
|---|---|
| Creating user (Randy Archambault) | Admin |
| `GB Fabric Administrators` `d27080d0-…` | Admin |
| Workspace identity SP `a8b0e71e-…` | Contributor |

## Audit-Dev (not deleted)

`39854263-5bae-4eb2-a9b6-6ba274d7476d` still has all 9 items, including the
Finance Executive Unit clone. That clone is presentation, not governance; it
was not copied.

## Non-goals

- Do not enable notebook schedules until a named review window
- Do not add this workspace to the Foundation deployment pipeline
- Do not provision Purview
- Do not move `pipeline_audit_cleanup` out of Foundation utilities
- Do not delete or disable Audit-Dev
