# BMX MI Phase 1 package README

**Date:** 2026-09-29 (updated 2026-10-01)  
**Owner:** Randall Anderson (Randy)  
**Active hub:** [`../buildermetrix-2026-10-01/`](../buildermetrix-2026-10-01/README.md)  
**This pack is the BuilderMetrix MI project detail:** Azure MI, Fortinet / CDW Phase 2, DNS, prelink, Link gates, rollback.  
**SQL standing DBA** (SQL03 + SQL04) lives in [`../sql-dba-2026-10-01/`](../sql-dba-2026-10-01/README.md).  
**General Fabric footprint** lives in [`../fabric-2026-10-01/`](../fabric-2026-10-01/README.md).

**Status:** SQL03 host prep for Link is done. Azure prelink dry-run PASS (2026-10-01). **Blocked on CDW Fortinet Phase 2** before Link. Existing HBLive/SPLive replication unchanged until Link. See `11-parallel-build-no-sql-impact.md`.

## Authority

`BMX-MI-Deployment-Spec.md` wins on product/SQL constraints.  
Live Azure inventory wins on connectivity: **FortiGate NVA in westus3**, not Azure VPN Gateway.

## Start here

1. [`00-recommended-plan.md`](00-recommended-plan.md) — full plan that will work  
2. [`00-blocking-tbds.md`](00-blocking-tbds.md) — recommended values + evidence  
3. [`CDW-Fortinet-Handoff-BMX-MI.md`](CDW-Fortinet-Handoff-BMX-MI.md) (+ PDF) — CDW Phase 2 handoff (in this pack)  
4. [`07-prelink-checklist.md`](07-prelink-checklist.md) — after Fortinet returns green

## Contents

| File | Purpose |
|---|---|
| `00-recommended-plan.md` | End-to-end plan aligned to FortiGate hub |
| `00-blocking-tbds.md` | Recommended register (was open TBDs) |
| `01-source-prep-verdict.md` | Source-Prep summary |
| `source-prep-results.txt` | Full read-only run output |
| `03-sql03-change-record.md` | MW + AG/-T1800 change record |
| `04-index-maintenance-change.md` | HBLive+SPLive REORGANIZE-only |
| `05-fortigate-change-request.md` | Security-actionable FortiGate CR (CIDR filled) |
| `CDW-Fortinet-Handoff-BMX-MI.md` (+ PDF) | CDW Phase 2 one-pager (in this pack) |
| `15`–`17` SQL03 notes | Host prep evidence (standing care → SQL03 DBA pack) |
| `06-monitoring-alerting.md` | Source log + MI redo controls |
| `07-prelink-checklist.md` | Executable checklist |
| `08-stage-gates.md` | Apply gates |
| `runbooks/*` | Stage 1–5 apply runbooks (not executed) |
| Spec/Parameters/SQL copies | Snapshots of Downloads inputs |

## Infrastructure code

See [`infrastructure/bmx-mi/`](../../../infrastructure/bmx-mi/).  
UDR next hop is **VirtualAppliance 10.1.2.4** (FortiGate internal).

## Source-Prep / host prep (confirmed)

- SQL03: 128 GB RAM, Enterprise 2019 — PASS  
- Always On + `-T1800` — applied; post-restart health green (see SQL03 DBA pack)  
- DMK — created; vaulted as `gbp-sql03-master-dmk`  
- Index — REORGANIZE split for HBLive+SPLive; job enabled  

## Next for humans

1. CDW completes Fortinet Phase 2 (handoff in this pack); return evidence to Randall.  
2. Prelink leftovers: V8 checksum backups, V15 modules on Link box; re-run after CDW (`18-prelink-dryrun-azure-2026-10-01.md`).  
3. Explicitly approve Link: HBLive then SPLive only.
