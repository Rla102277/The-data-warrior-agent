# Foundation hydration runbook (GATED)

**Status:** Prepared 2026-08-12. Updated 2026-08-19.

Standing rules: D12 (no legacy destruction). Recurring schedules stay OFF
in FD and Foundation unless a named window says otherwise. Salesforce
outbound remains `IsActive=N`. SOX / git wiring stays blocked separately.

## Approved: Foundation Development one-shot (2026-08-17 ~22:13 Central)

Explicit go-ahead 2026-08-17: **dev** hydration tonight in **Foundation
Development** only. Fabric runs it. This Mac is not in the path.

| Field | Value |
|---|---|
| Workspace | Foundation Development (`40502864-6ece-49b5-807f-6f7c11d1b3e1`) |
| Step 1 | `pipeline_stage_orchestrator` Daily **22:13** Central (schedule `e96424b6-…`) |
| Step 2 | `pipeline_operations_analytics_refresh` Daily **22:45** Central (schedule `3934123c-…`) |
| Window | Both schedules start 21:00 and **end 23:59 tonight**. They do not repeat. |
| 15-min cron | Stay **disabled** on both pipelines |
| Foundation twin | **Not** in this window |
| History / Zonda / SF outbound | Not in this window |

Capacity (confirmed 2026-08-17 afternoon): shared F32. Enterprise
`pp_orchestration_without_pp_audit` still runs every 15 min at :06/:21/:36/:51
Central and finishes in about 6-9 minutes. FD jobs are offset into the
quiet gaps and are serialized (orchestrator, then 32 minutes later refresh)
so they do not stack on each other or on an Enterprise start. Analytics
refresh historically ~13 minutes, so it can clip the 22:51 Enterprise tick;
that is a short overlap, not a triple stack. Do not enable FD 15-minute
cron. Do not start a Foundation twin load tonight.

If orchestrator fails, disable the 22:45 refresh in Fabric (or
`DELETE .../schedules/3934123c-bce1-4602-b630-fb2c2ca34e85`) before 22:45.

**Result (confirmed 2026-08-18 morning):** Both scheduled jobs Completed.
Orchestrator 22:13-22:21 Central (491s). Analytics refresh 22:45-22:56
Central (673s). OneLake `operations/`: 0 `_backup_<guid>` folders; 29
published tables lastModified 18 Aug. One-shot schedules disabled after
the run so they do not fire again. 15-minute cron still off.

## Approved: Foundation twin one-shot (2026-08-18 ~22:13 Central)

Explicit go-ahead 2026-08-18: **"10pm tonight make dev and prod foundation
match."** Additive copy/rebuild in the Foundation twin only. Fabric runs
it. This Mac is not in the path. Do not enable recurring after this
window.

| Field | Value |
|---|---|
| Workspace | Foundation (`7c1850c1-821f-4fc7-a823-c186516023c6`) |
| Step 1 | `pipeline_stage_orchestrator` Daily **22:13** Central (schedule `0fac8959-bbec-43fc-a327-35b8663967b7`) |
| Step 2 | `pipeline_operations_analytics_refresh` Daily **22:45** Central (schedule `6da6ddeb-7ee3-4717-819f-2dd687c4418c`), pipeline default `p_domain=all` |
| Window | Both schedules start 21:00 and **end 23:59 tonight**. They do not repeat. |
| 15-min cron | Stay **disabled** on FD and Foundation |
| FD | Left **OFF** (15-min and leftover 17 Aug Dailies remain disabled) |
| History / Zonda / SF outbound | Not in this window. Promoted gap pipelines stay unscheduled. |

22:45 (not 22:50) for analytics: last proven FD window. A first Foundation
FULL of ~13.5 min from 22:13 still ends around 22:26, so 22:45 keeps the
same gap after orchestrator and after the 22:36 Enterprise tick. Do not
start at 22:00.

If orchestrator fails, disable the 22:45 refresh in Fabric (or
`DELETE .../schedules/6da6ddeb-7ee3-4717-819f-2dd687c4418c`) before 22:45.

**Afternoon prep (confirmed 2026-08-18):** Third promote of 9 FD-only
items Succeeded (deploy `9cc6b47e-…`). Unpaired `analytics/Title` and
`utilities/salesforce` folders caused `TargetSubfolderNameConflict`;
items were moved to paired parent folders for deploy, then placed in
Foundation analog folders. Pipeline SQL hosts rebound on the 4 new
pipelines. Semantic models rewritten to Foundation host /
Foundation Lake (`73fac61d-…`). `control.analytics_refresh_config`
reseeded to **29** rows (current FD contract; no `*_active` twins;
`pipeline_health_obt` warehouse-only). Disable-after-run is required
in the morning even though `endDateTime` is 23:59 tonight.

**Result (confirmed 2026-08-19 morning):** Mixed. Orchestrator Completed;
analytics refresh Failed. FD one-shots did not fire. Daily one-shots
disabled after the run. 15-minute cron stayed off. Semantic model
refresh and report spot-check were not in the overnight window and
have not run.

| Job | Item | Instance | Start (Central) | End (Central) | Duration | Status |
|---|---|---|---|---|---:|---|
| Orchestrator | `pipeline_stage_orchestrator` `271a80ac-8be1-4129-ade8-e85c9b4ab398` | `0e0bf12c-a462-43eb-9b49-8f4933de0141` Scheduled | 2026-08-18 22:13:02 | 22:26:38 | 815s | **Completed** |
| Analytics refresh | `pipeline_operations_analytics_refresh` `4ce7479e-b8cb-48ef-b63d-c2afe923544d` | `989b836c-b44f-4636-a01d-c62723e2fee5` Scheduled | 2026-08-18 22:45:02 | 22:56:16 | 673s | **Failed** |

Refresh failure (confirmed from job `failureReason`): ForEach
`refresh_targets` / inner `copy_to_lakehouse` source error `Invalid
object name 'analytics.lot_events_obt'`. Orchestrator still Completed;
refresh still ran because the 22:45 Daily was left enabled through the
window.

Lakehouse `lake_house_analytics` `811e901e-…` OneLake
`operations/`: **19** published tables, **0** `*_backup_<guid>` folders.
All 19 lastModified 2026-08-18 22:45:47 to 22:54:26 Central (during the
failed refresh). Missing 10 of the 29-row contract:
`plan`, `lot_events_obt`, `lot_obt`, `sale_obt`, `lot_financials_obt`,
`sales_sum_weekly`, `unit_sum_weekly`, `sales_sum_monthly`,
`sales_gross_margin_assumptions_det`, `title_booking_obt`.

Warehouse `warehouse_stage` (read-only, cheap):
`control.analytics_refresh_config` is **29** active rows in both
Foundation and FD. Foundation `analytics` has 39 views and is missing
the same 10 names (plus `lot_events_obt` `OBJECT_ID` is null). FD has
50 analytics views and all 29 contract names, including
`lot_events_obt`. Inferred: dbt contract views were not deployed to
Foundation warehouse_stage before the twin refresh; config was reseeded
to 29 anyway.

FD comparison (did not run 18 Aug night): last jobs remain the 17 Aug
one-shot (orch `35579f59-…` Completed 22:13-22:21 Central 491s; refresh
`36c2b790-…` Completed 22:45-22:56 Central 673s). FD lakehouse has 49
published tables (29 contract + 20 leftover `*_active` / old names), 0
backups; contract tables lastModified 17 Aug 22:45-22:55 Central.

Disable-after-run (confirmed 2026-08-19 morning): PATCH
`enabled=false` on Foundation Daily `0fac8959-bbec-43fc-a327-35b8663967b7`
(orch 22:13) and `6da6ddeb-7ee3-4717-819f-2dd687c4418c` (refresh 22:45).
Workspace scan after that: **0** enabled schedules in Foundation and
FD. 15-min cron remains disabled (`86b166ae-…` orch, `9e8f951b-…`
refresh). Do not retry refresh until the 10 missing `analytics.*` views
exist in Foundation warehouse_stage. Do not enable 15-minute cron.

### Morning leftovers (still open 2026-08-19)

- [ ] Deploy missing Foundation `analytics` views (the 10 names above),
      then rerun `pipeline_operations_analytics_refresh` `p_domain=all`
      as a **manual** job. Do not enable schedules.
- [ ] Semantic model refresh in Foundation: CustSat, 4 Finance, sales,
      lot events, title booking (Power BI refresh history empty this
      morning; not started)
- [ ] Spot-check Foundation reports (CustSat, Finance, sales, lot events)
- [ ] Optional: `python3 automation/parity_check.py`
- [x] Leave schedules OFF. Do not enable 15-minute cron. SOX/git still
      blocked separately.

## Preconditions

- [ ] Explicit approval with date/time window (Central)
- [ ] Shared F32 capacity headroom (avoid mid-morning)
- [ ] FD schedules confirmed OFF
- [ ] Foundation schedules confirmed OFF
- [ ] Parity script ready: `python3 automation/parity_check.py`
- [ ] Endpoint rebind validated: `python3 automation/rebind_endpoints.py "Foundation"`
- [ ] Alert activators present in FD and Foundation
- [ ] Key Vault Secrets User for WI group (Zonda optional for this window)

## Wave plan

Run in **Foundation** only (`7c1850c1-821f-4fc7-a823-c186516023c6`).

| Step | Action | Gate before next |
|---|---|---|
| 0 | Pause any accidental FD schedules; announce window | n/a |
| 1 | `pipeline_stage_orchestrator` with default params, wave slot 1 entities only (or full orchestrator once if config already wave-scoped) | `control.audit_sp_control` SUCCESS for wave 1; row-count spot check vs FD |
| 2-6 | Continue waves 2-6 | Same gate each wave |
| 7 | Optional: `pipeline_stage_history_load` if Finance confirms hist need | Hist row counts > 0 |
| 8 | `pipeline_operations_analytics_refresh` `p_domain=all` | 29 published entities present; backup cleanup notebook succeeded |
| 9 | Semantic model refresh: CustSat + 4 Finance SMs | Bindings on Foundation Lake / Foundation dataverse |
| 10 | Report spot-check from Foundation twin | Visual sanity |
| 11 | `python3 automation/parity_check.py` | Results in `control.parity_check`; triage DRIFT |
| 12 | Leave schedules OFF until cutover decision | n/a |

## Commands (operator)

```bash
# Validate hosts only
python3 automation/rebind_endpoints.py "Foundation"

# After each wave (read-only parity write to control)
python3 automation/parity_check.py

# Analytics refresh is a Fabric pipeline run (UI or fab job run). Do not
# enable cron. Manual run of pipeline_operations_analytics_refresh only.
```

## Abort criteria

- Capacity sustained > 85% for > 10 minutes
- Orchestrator FAILED with blocked RUNNING audit row (clear via inline delete path)
- Parity DRIFT on truncate-and-load entities (company, calendar) that previously matched in FD

## After success

Document run id, duration, and parity summary in
`knowledge/operations/deployment-pipeline.md` change log. Promote remaining
gap pipelines (wave 3) only after hydration if they were not already promoted.
