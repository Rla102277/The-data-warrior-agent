# Schedule truth table

**Documented:** 2026-07-15 (evaluation date for expired vs active)  
**Workspace:** GBP-Enterprise unless noted  
**Sources:** pipeline `.schedules` exports, Reflex `ReflexEntities.json`, prior Salesforce schedule export, `control.audit_orchestrator_control`, job run cadence

---

## How to read status

| Status | Meaning |
|---|---|
| **active** | `enabled=true` and `endDateTime` still in the future as of 2026-07-15 |
| **expired** | `enabled=true` but `endDateTime` already passed (will not fire) |
| **disabled** | `enabled=false` in definition |
| **reflex-alert** | Fabric Reflex listens for job failures (does **not** start the pipeline) |
| **operational cadence** | Not in `.schedules` (or export missing) but run history shows a steady clock |

Do not treat `enabled=true` alone as live. Several jobs are enabled and expired.

---

## Pipeline schedules (definition export)

| Pipeline | Status | Type | Cadence | Time zone | Window | Notes |
|---|---|---|---|---|---|---|
| `pp_orchestration_without_pp_audit` | **active** | Cron | every 15 min | Central | 2025-12-22 → 2026-12-31 | Primary EDW driver; audit table shows recent SUCCESS |
| `pp_delete_blocked_logs` | **active** | Cron | every 120 min | India Standard | 2026-03-26 → 2027-03-26 | Utility cleanup |
| `pp_audit_cleanup` | **expired** | Daily | 00:00 | Central | ends 2025-12-31 | Still marked enabled |
| `pp_compare_azure_vs_mirrored_db` | **expired** | Daily | 06:30 | Eastern | ends 2025-12-31 | Still marked enabled |
| `pp_fact_hist_scheduled` | **expired** | Daily | 00:00 | Central | ends 2025-12-31 | Hist orchestrator |
| `pp_load_stg_to_dim_project` | **expired** | Daily | 06:00 | Central | ends 2025-05-23 | Short test window |
| `pp_orchestration_with_pp_audit` | **disabled** | Cron | every 30 min | Central | through 2026-12-17 | Audit orchestrator |
| `pp_orchestration` | **disabled** | Cron | every 15 min | Central | ends 2025-12-31 | Base InvokePipeline orch |
| `pp_orchestrator_test` | **disabled** | Cron | every 15 min | India Standard | Jul 2025 only | Test |
| `pp_load_stg_to_dim_operating_unit` | **disabled** | Daily | 06:00 | Central | May 2025 | One-off |
| `pp_fabric_salesforce_ingestion_prod` | **disabled** | Cron | every 10 min | Central | through 2029 | Children; parent orch drives runs |
| `pp_salesforce_fabric_ingestion` | **disabled** | Cron | every 10 min | Central | through 2029 | Non-prod named inbound |

**Count:** 2 active, 4 expired, 6 disabled (among pipelines that have a `.schedules` file).

Most of the 90 pipelines have **no** native schedule; they are invoked by orchestrators or run manually.

---

## Salesforce operational cadence

| Item | Evidence | Cadence |
|---|---|---|
| `pp_salesforce_orchestrator_prod` | 2026-07-14 definition export had **enabled Daily** at 10:00 / 13:00 / 16:00 Central through 2027-06-25 | Treat as **operational cadence** |
| Same item on 2026-07-15 export | No `.schedules` file in export payload | Export gap; do not assume schedule removed without UI/API confirm |
| Child pipelines | Run history shows Manual invokes ~15:00 / 18:00 / 21:00 UTC (= 10 / 13 / 16 CDT) | Matches Daily clock |
| Child self-schedules | Disabled 10-min Crons | Not the driver |

---

## Reflexes (failure alerts, not schedulers)

All Confirmed as `Microsoft.Fabric.JobEvents.ItemJobFailed` → email. `shouldRun: true`.

| Reflex | Watches artifact | Alert email (from definition) |
|---|---|---|
| `act_pp_orchestration_without_pp_audit` | `pp_orchestration_without_pp_audit` | randerson@greenbrickpartners.com |
| `act_pp_orchestration_with_pp_audit` | `pp_orchestration_with_pp_audit` | randerson@greenbrickpartners.com |
| `act_pp_salesforce_orchestrator` | `pp_salesforce_orchestrator_prod` | randerson@greenbrickpartners.com |
| `act_load_zonda_to_fabric_alerts` | `pp_load_zonda_to_fabric` | adhanraj@GreenBrick1.onmicrosoft.com |
| `act_job_event_failure_alerts` | tied to `pp_salesforce_fabric_ingestion` artifact id in source binding | kradhakrishnan@GreenBrick1.onmicrosoft.com |

These do **not** replace schedules. They only notify on failure.

---

## What is actually driving production today (synthesis)

| Process | Driver | Confidence |
|---|---|---|
| EDW incremental dims/facts | `pp_orchestration_without_pp_audit` 15-min Cron | **High** (schedule active + orchestrator audit SUCCESS) |
| Salesforce sync | `pp_salesforce_orchestrator_prod` Daily 10/13/16 Central | **High** operational cadence; definition schedule file inconsistent on 2026-07-15 export |
| Mirror compare / audit cleanup / fact hist nightly | Schedules expired | **Not running** unless manually invoked |
| Failure notification | Reflexes above | **High** |

---

## Recommended cleanup

1. Extend or disable-and-document expired schedules (`pp_audit_cleanup`, mirror compare, fact hist).  
2. Confirm Salesforce orchestrator schedule in Fabric UI / Jobs API (export missed `.schedules`).  
3. Keep a single EDW driver (`without_pp_audit` vs `with_pp_audit`) to avoid dual cadence if the disabled orch is ever re-enabled.  
4. Align utility schedules to Central (or document why IST is intentional for `pp_delete_blocked_logs`).

---

## Refresh query

```bash
# After fab export of a pipeline:
cat path/to/<pipeline>.DataPipeline/.schedules

# Reflexes:
fab export GBP-Enterprise.Workspace/<name>.Reflex -o /tmp -f
```
