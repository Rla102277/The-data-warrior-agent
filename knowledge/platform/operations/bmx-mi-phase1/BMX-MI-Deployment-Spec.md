# BuilderMetrix — Azure SQL Managed Instance Deployment Spec

**Purpose.** Build the Azure SQL Managed Instance that serves as the replica target for
BuilderMetrix, and establish Managed Instance Link from the on-premises source server.

**Audience.** This document is the input to a technical deployment plan. Every value below is
either measured from the live environment or confirmed by the vendor. Items marked
`[UNRESOLVED]` are genuinely open and must not be guessed — surface them rather than
choosing a default.

**Owner.** Randall Anderson, VP IT, Green Brick Partners. Change control owner.
**Vendor.** Constellation HomeBuilder Systems (CHS).
**Date of record.** 2026-09-29.

---

## 1. Context

Green Brick Partners is deploying BuilderMetrix, a Constellation reporting/analytics platform.
BuilderMetrix reads from replicas of GBP's production databases hosted in an Azure SQL Managed
Instance inside GBP's own Azure tenant. All infrastructure cost sits on the GBP tenant.

Data flows: on-prem SQL Server → (MI Link) → Azure SQL MI → BuilderMetrix warehouse →
Microsoft Fabric (existing F64 capacity, unlimited Power BI licensing included).

An Azure SQL Database was ruled out by CHS: Azure SQL DB has no SQL Agent, and the Change
Tracking extraction job requires it.

**Hard deadline.** Internal target is end of year 2026.

---

## 2. Source environment (measured)

### 2.1 Server — GBP-SQL03

| Property | Value |
|---|---|
| SQL Server version | 15.0.4460.4 (SQL Server 2019) |
| Edition | Enterprise Edition: Core-based Licensing (64-bit) |
| Logical cores | 8 |
| Physical RAM | 128 GB (upgraded 2026-09-18 from 64 GB) |
| max server memory | 112,640 MB |
| MAXDOP | 4 |
| Cost threshold for parallelism | 100 |
| Lock Pages in Memory | Enabled (`LOCK_PAGES`) |
| Instant File Initialization | Enabled |
| **Server collation** | **`SQL_Latin1_General_CP1_CI_AS`** |
| Service account | `gb\sa_SQL` |

GBP-SQL03 is not a dedicated database host. It is also the replication **distributor**,
publisher for HBLive and SPLive, and runs SSIS packages. Factor this into any change that
requires a service restart.

### 2.2 Databases in replication scope

| Database | Size | Recovery model | Compat level | Collation | Replication role |
|---|---|---|---|---|---|
| HBLive | 299.9 GB | FULL | 140 | `SQL_Latin1_General_CP1_CI_AS` | Published |
| SPLive | 20.2 GB | FULL | 140 | `SQL_Latin1_General_CP1_CI_AS` | Published |
| BUILDPRO | 34.4 GB | **SIMPLE** | 150 | `SQL_Latin1_General_CP1_CI_AS` | **Push subscriber** |

HBLive is the NEWSTAR Enterprise (NSE) ERP database. SPLive is NEWSTAR Sales (NSS).

**HBLive and SPLive are the only databases in scope for this deployment.** BUILDPRO is listed
for context only — see §6. Do not plan MI Link steps for it.

### 2.3 Workload characteristics (8-day sample, 2026-09-01)

| Metric | HBLive | SPLive |
|---|---|---|
| Data allocated | 284.90 GB | 11.51 GB |
| Data used | 261.06 GB | 11.41 GB |
| Log allocated | 9.59 GB | 8.55 GB |
| Average IOPS | 312 | 11 |
| Log generation per day | 22.7 GB | 1.6 GB |
| Data-file write latency | 38 ms | 60 ms |
| Growth | ~3.8 GB/month | — |

Combined log generation ≈ **24 GB/day**. This is the figure that sizes the tunnel and the
geo-redundant backup bandwidth.

Concurrency at sampling: 1,255 sessions against HBLive across 3 service logins and 9 hosts;
58 sessions against SPLive across 30 logins.

### 2.4 Largest objects in HBLive

Relevant because index maintenance on these generates the log spikes discussed in §7.

| Index | Size |
|---|---|
| `interfacelogl#_#progress_recid` (CLUSTERED) | 43,069 MB |
| `detail#_#progress_recid` (CLUSTERED) | 10,351 MB |
| `apdetail#_#progress_recid` (CLUSTERED) | 9,582 MB |
| `interfacelogl#_#progress_recid_ident_` | 8,383 MB |
| `eventlog#_#progress_recid` (CLUSTERED) | 8,256 MB |
| `interfacelogl##logid_filename` | 8,052 MB |

`interfacelogl` totals roughly 65 GB across its four indexes; `eventlog` adds 8.3 GB.
Whether these are in BuilderMetrix replication scope is `[UNRESOLVED]` — see §10.

---

## 3. Target configuration

Specification from Clint Scherbarth (CHS Director of IT), 2026-09-01, benchmarked against a
live NSE deployment rather than the generic CHS starting baseline.

| Dimension | Value | Basis |
|---|---|---|
| Service tier | Next-gen General Purpose | Exposes Premium-series hardware and independent sliders |
| Hardware | Premium-series, Intel Ice Lake | 7 GB/vCore vs 5.1 on Standard; 8/10/12 vCore steps |
| vCores | 10 | Reference saturated 4 vCores for 2.5–3.4 hrs/day on a source one-fifth this size |
| Reserved storage | 1,024 GB | Replica 315 GB + warehouse + warehouse log + ~100 GB 24-mo growth + CT overhead |
| Built-in IOPS | 3,072 | 3 IOPS per GB reserved, included in storage price |
| Additional IOPS | ~3,000 (≈6,000 total) | Covers reference peaks of 5,100–7,046 |
| Memory | 70 GB | Native at 7 GB/vCore on Premium-series; no slider needed |
| Backup redundancy | Geo-redundant | CHS specification |
| Licence type | Azure Hybrid Benefit | `[UNRESOLVED]` — see §10 |

CHS confirmed the 34 GB BuildPro database **is included** in the 1,024 GB recommendation
(Clint Scherbarth, 2026-09-21).

MI Link supports SQL Server 2017 and later at compatibility level 140. All three source
databases qualify.

### 3.1 Settings that CANNOT be changed after creation

Getting any of these wrong means deleting the instance and rebuilding. Verify each before
deployment.

| Setting | Required value |
|---|---|
| **Instance collation** | **`SQL_Latin1_General_CP1_CI_AS`** — the portal default is different. MI collation must match the source or the link cannot be established. |
| **Time zone** | **Central Standard Time** — governs SQL Agent schedules, including the 15-second Change Tracking sync job. |
| **Virtual network / subnet** | Permanent binding. Moving the instance later is a rebuild. |
| **Instance name / DNS zone** | Forms the FQDN every downstream connection uses. |

Everything else — vCores, storage, IOPS, memory, backup redundancy — is adjustable online
after creation. Do not over-provision defensively on those.

---

## 4. Network design

### 4.1 Existing connectivity

GBP has an **Azure VPN Gateway** connecting Azure Firewall to the corporate data center via
**Fortinet/FortiGate**. ExpressRoute is not in use and is not being pursued.

The MI Link public endpoint supports **TDS only** (SQL querying), not replication traffic.
Private connectivity is mandatory and must work bidirectionally.

### 4.2 Virtual network and subnet

- Region must match or peer to the VNet where the existing VPN Gateway terminates.
- Dedicated subnet used for nothing else, delegated to `Microsoft.Sql/managedInstances`.
- **Minimum /27; /26 or larger recommended.** Scaling operations temporarily double the
  address requirement, and the subnet cannot be resized without rebuilding the instance.
- The subnet must contain no other resource.

### 4.3 Route table

Associate a route table with the subnet. Azure adds the required service management routes.
Add a route for the on-premises address space pointing at the VPN gateway so return traffic
to GBP-SQL03 routes correctly rather than following the default internet path.

### 4.4 Network security group

Inbound from the on-premises address range — scope to that range, never `Any`:

| Port | Purpose |
|---|---|
| TCP 5022 | Database mirroring endpoint (MI Link) |
| TCP 1433 | Standard SQL connectivity |
| TCP 11000–11999 | Redirect-mode traffic |

On the GBP side, the FortiGate requires the reciprocal opening: inbound TCP 5022 from the MI
subnet range, and outbound to that subnet across the same ports.

### 4.5 IPSec Phase 2 rekey alignment — REQUIRED

Raised by Alex Osokin (CHS Director of Custom Development) in the design review of
2026-09-18, based on incidents at other large CHS customers.

> "For the most part, it works, but we have a couple of larger customers I interact with where
> things got interesting because the tunnel would 'randomly' blip. When it blips, your DB redo
> length on the MI target becomes long and, if left unchecked, creates a performance hazard."

The cause is unaligned IPSec rekeying. Key renegotiation happens in two planes: Phase 1 and
Phase 2. **Phase 1 is not configurable on the Azure VPN Gateway; Phase 2 is.** The FortiGate
Phase 2 settings must be aligned with the Azure Gateway configuration.

This is not optional hardening. See §7 for why a tunnel blip is a production risk on the
source server, not just a replication inconvenience.

---

## 5. Deployment sequence

### Stage 1 — Network foundation

Build the network before the instance. A Managed Instance deployment fails late and slowly
if the subnet is wrong, and each failed attempt costs several hours.

1. VNet and delegated subnet (§4.2)
2. Route table (§4.3)
3. NSG (§4.4)
4. FortiGate firewall change: reciprocal ports + Phase 2 rekey alignment (§4.4, §4.5)
5. Verify bidirectional connectivity before proceeding

### Stage 2 — Create the Managed Instance

Portal path: Create a resource → Azure SQL → Azure SQL Managed Instance → Single instance.
**Expect 4–6 hours.** The first instance in a subnet takes longest because the virtual cluster
is built at the same time.

- **Basics** — subscription, resource group, instance name, region matching the VNet.
  Microsoft Entra authentication with a SQL admin fallback account. Record credentials in the
  password vault immediately; the admin login cannot be recovered, only reset.
- **Compute and storage** — per §3. Reserved storage carries 3 free IOPS/GB, so 1,024 GB
  yields 3,072; move the IOPS slider up ~3,000 to reach ~6,000 total.
- **Networking** — subnet from Stage 1. **Public endpoint disabled.** Connection type
  **Proxy** rather than Redirect (Redirect requires 11000–11999 open from every client).
  Minimum TLS version 1.2.
- **Security** — enable Microsoft Defender for SQL. Enable auditing to Log Analytics or a
  storage account at creation rather than retrofitting; this instance holds financial
  reporting data and sits within the ITGC control scope. TDE is on by default with a
  service-managed key.
- **Additional settings** — **collation and time zone per §3.1.** Leave geo-replication
  alone; the link is established separately in Stage 4.
- **Review and create** — verify collation, time zone and subnet before deploying.

One caveat on redundancy: flexible memory is generally available on locally redundant
Premium-series instances but remains in preview on zone-redundant instances. If zone
redundancy is wanted, confirm the memory configuration is supported before committing.

### Stage 3 — Source preparation on GBP-SQL03

Runs in parallel with Stage 2. **Change Tracking enablement is CHS's responsibility** — no
CT work belongs here.

Run `BMX-MI-Source-Prep.sql` first; it validates every prerequisite read-only and reports
what needs changing.

1. **Database master key** in `master` if one does not exist. MI Link uses certificates to
   encrypt authentication between both sides; the master key protects them.
2. **Enable the Always On availability groups feature** in SQL Server Configuration Manager.
   **This requires a SQL Server service restart.** On a production ERP instance that means a
   maintenance window. This is the longest-lead item in the whole deployment — schedule it
   early.
3. **Trace flag `-T1800`** as a startup parameter. Optimises performance where primary and
   secondary replicas host log files on disks with different sector sizes, which is the normal
   case when replicating to Azure. Applied in the same restart as item 2.
4. **Backup checksums enabled**, FULL recovery model, and a full backup taken for every
   database in scope. See §6 for the BUILDPRO exception.
5. **PowerShell modules**: `Az.Sql` ≥ 3.9.0, `Az.Accounts` ≥ 2.8.0, `SqlServer` ≥ 21.1.18256.
6. **Index maintenance change** per §7 — before the link goes live.

### Stage 4 — Establish the link

Per Microsoft's MI Link procedure, one database at a time. The account establishing the link
needs the **SQL Managed Instance Contributor** role, or a custom role carrying the hybrid
certificate, distributed availability group, hybrid link and server trust certificate
permissions. Scope this deliberately — it will be documented for SOX alongside the Fabric
service principal.

### Stage 5 — Post-deployment

- Set the maintenance window explicitly. Avoid month-end close, which is both the heaviest
  reporting period and when the gross margin snapshot subscriptions run.
- Configure diagnostic settings to Log Analytics — CPU, storage IO, memory. Clint's reference
  instance sat above its IOPS quota for up to 240 minutes/day; this telemetry is what
  determines whether 6,000 IOPS holds once the warehouse build runs.
- Configure monitoring for source-side log growth per §7.

---

## 6. BUILDPRO — context only, NOT in this deployment

**BuildPro is out of scope for the initial build. Do not generate deployment steps for it.**

Constellation will source BuildPro from the vendor and replicate it into the Managed Instance
themselves. GBP does not stand up that path. Decision of 2026-09-29, superseding the
2026-09-19 position that GBP would replicate BuildPro directly.

Retained here because it affects sizing and capacity planning, and because it will land in the
same instance later:

- BUILDPRO is 34.4 GB. Clint Scherbarth confirmed on 2026-09-21 that this 34 GB **is already
  included** in the 1,024 GB reserved storage recommendation. Do not subtract it.
- GBP currently receives BUILDPRO on GBP-SQL03 as a read-only push subscription from the
  vendor (publisher `SWU2-REPSQL-01`, publication `GRBKBuildRepl`, `subscription_type = 0`,
  `update_mode = 0`). That on-premises copy is unaffected by this work and continues as-is.
- The on-premises copy is in SIMPLE recovery and carries GBP-added custom indexes protected by
  a guard job. Neither matters for the MI build, since GBP is not linking this database.
- When Constellation's BuildPro replication does arrive in the MI, it adds write volume to the
  instance. Relevant to the IOPS and CPU headroom in §3, not to the build steps.

Nothing in Stage 3 (§5) applies to BUILDPRO. The index maintenance change in §7 is scoped to
HBLive only.

---

## 7. Transaction log risk on the source — design constraint

This is the single most important operational risk in the design, raised by Alex Osokin:

> "The MI link is basically a special case of Always On Avail Group (AG), the so-called
> 'distributed AG'. In a distributed AG, the primary replica (which in this case is SQL003)
> can't truncate transaction log records until they are replicated to the secondary. If the
> tunnel blips or there is a problem of any kind where the MI can't handle volume spikes, then
> the source DB log grows and grows and, 'eventually', puts the source DB into a
> no-writes-allowed mode. This happens more than one would think it does."

A no-writes state on HBLive is a production ERP outage. Three mitigations are in the design:

**Tunnel stability** — Phase 2 rekey alignment, §4.5.

**Index maintenance must not generate single-transaction log spikes.** Index REBUILD is a
fully-logged single-transaction operation; REORGANIZE commits incrementally and allows the log
to truncate as it proceeds. Measured over 30 days on GBP-SQL03:

| Database | Operation | Operations | Total min |
|---|---|---|---|
| HBLive | REORGANIZE | 836 | 468.9 |
| HBLive | REBUILD | 8 | 0.2 |
| SPLive | REORGANIZE | 228 | 24.0 |

Rebuilds are already almost non-existent on HBLive, so the change costs essentially nothing.
The reason to make it is the tail risk: `interfacelogl` is a 43 GB index, and a rebuild of it
would be one fully-logged transaction pushed through the tunnel as a single spike.

**Action:** in the SQL Agent job `GBP - Index Maintenance` on GBP-SQL03, change
`@FragmentationHigh` from `'INDEX_REBUILD_ONLINE,INDEX_REORGANIZE'` to `'INDEX_REORGANIZE'`
for **HBLive and SPLive only** — the two databases being linked. Other databases keep the
current setting. This requires splitting the current tier-1 step, which today covers all
production and reporting databases in a single `IndexOptimize` call.

**Change Tracking chain reaction.** Alex also flagged that the CT extraction job on SQL03
writes into 4 custom tables in the same database as the source tables:

> "we basically have a possible chain reaction log file growth - we spike writes into the
> origin tables (eats up log) and then, X<15 min later, we spike them again to write to the
> change tables."

Named as additional spike sources: massive BuildPro file ingestions, master project, recalc
projections, and build lot budget jobs. The BuildPro ingestion concern applies to writes
landing in HBLive, not to the BUILDPRO database itself.

**Monitoring requirement.** Source-side log space and MI redo queue length must both be
monitored from day one, with alerting on log space consumption for HBLive and SPLive.

---

## 8. Out of scope for phase 1

**Stella and CHS AI artifacts.** Decision of 2026-09-19. Requires the BMX MCP server to run
in GBP's Azure via App Service for containers, plus either hosting a container repository or
establishing cross-tenant authentication into the CHS-hosted one, plus two specific Entra app
registrations. CHS also has no established mechanism for exposing custom tables (e.g. added
BuildPro tables) as MCP tools. Phase 2.

**Data Gateway.** Not required. MI Link replaces it; Fabric mirroring runs directly from the
BMX database. Confirmed at kickoff 2026-08-24. Any older documentation referencing a Data
Gateway is stale.

---

## 9. Downstream dependencies

**Fabric.** GBP has existing F64 capacity with unlimited Power BI licensing included. GBP
wants an isolated Fabric workspace for audit clarity, plus a dev-to-prod promotion path.

**Fabric service principal.** CHS requires a service principal for the Fabric environment for
programmatic deployments and updates. Per Seamus Mulroy: it needs only the permissions
required for the Fabric REST APIs and is assigned directly to the Fabric workspace. Setup
guidance is owed by CHB Tech Services; GBP wants a live working session rather than email.
Permissions must be scoped tightly and documented for SOX.

**Change Tracking.** CHS handles enablement. The final source table list and an
enable/disable script are owed by CHS — GBP needs a repeatable deployment script because CT
periodically has to be stopped and rebuilt.

**Row-level security** is available out of the box. **Column-level security is not.**

---

## 10. UNRESOLVED — do not guess

| # | Item | Impact | Owner |
|---|---|---|---|
| 1 | **BuilderMetrix warehouse size.** Seamus Mulroy's guidance was 30–40% of source data (~80–105 GB); Clint Scherbarth's reference deployment showed the warehouse at **2.3× source data** (~600 GB against 261 GB of HBLive). Clint's own email hedges: "warehouse 260-600 (1-2.3x of 261 GB)". | Determines whether 1,024 GB reserved storage is correct. Storage is adjustable online, so this does not block provisioning. | CHS |
| 2 | **Logging tables in replication scope.** `interfacelogl` (~65 GB across indexes) and `eventlog` (~8 GB) dominate HBLive. If BuilderMetrix does not consume them, excluding them reduces both MI storage and daily tunnel volume materially. | Storage sizing and tunnel bandwidth. | CHS |
| 3 | **Azure Hybrid Benefit entitlement.** GBP-SQL03 runs SQL Server 2019 Enterprise under core-based licensing, so AHB very likely applies. Unconfirmed against the licensing agreement. Estimated swing ~$10K/year. | Cost only. Selectable at creation and changeable afterwards. | GBP licensing |
| 4 | **Azure region.** Must match or peer to the VNet terminating the existing VPN Gateway. | Determines every downstream resource. | GBP |

---

## 11. Source document set

| File | Contents |
|---|---|
| `BMX-MI-Deployment-Spec.md` | This document |
| `BMX-MI-Source-Prep.sql` | Read-only pre-flight validation for GBP-SQL03 |
| `Azure SQL MI Build Runbook - BuilderMetrix.docx` | Earlier narrative runbook. Superseded where it conflicts with this spec: it predates the BuildPro scope decision, still presents VPN vs ExpressRoute as open, and references a Data Gateway that is no longer required. |
| `BMX_Infrastructure_Benchmarks.xlsx` | Source sizing and performance benchmark data |

---

## 12. What the deployment plan must produce

1. Infrastructure-as-code or scripted deployment for the network foundation (§4) and the
   Managed Instance (§3, §5 Stage 2), with the four irreversible settings (§3.1) asserted
   explicitly rather than defaulted.
2. A firewall change request for the FortiGate covering reciprocal ports and Phase 2 rekey
   alignment (§4.4, §4.5).
3. A source-preparation change record for GBP-SQL03 including the service restart required to
   enable availability groups and apply `-T1800` (§5 Stage 3).
4. The index maintenance change (§7), scoped to HBLive and SPLive only.
5. Monitoring and alerting for source log space and MI redo queue (§7).
6. Validation steps proving bidirectional connectivity and collation match before the link is
   attempted.

Do not resolve §10 by assumption. Where an unresolved item blocks a step, state the
dependency and stop.
