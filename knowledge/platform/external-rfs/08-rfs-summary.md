# RFS summary (Request for Services)

**Purpose:** Engage a partner on **time-and-materials or managed services** against the Foundation capability model, when scope is evolving (Mortgage, TM1, Purview) or when staff augmentation is preferred over fixed SOW.

**Difference from RFP:** RFS emphasizes **roles, rates, cadence, and governance** over a fixed feature list. Deliverables are sprint-based with a prioritized backlog.

## 1. Engagement model

| Option | Description | Best when |
|---|---|---|
| **A. Managed squad** | Vendor provides Fabric architect + dbt engineer + part-time PM | Steady 6-12 month rebuild |
| **B. Staff augmentation** | Named individuals embedded in Green Brick team | Internal PM owns backlog |
| **C. Advisory + burst** | Retainer for architecture review; surge for migrations | Cutover windows |

Green Brick retains product ownership, D12 prod safety, and deployment approval.

## 2. Service capabilities required

Vendor personnel must be capable in:

| Capability | Minimum proficiency |
|---|---|
| Microsoft Fabric (pipelines, lakehouse, warehouse, deployment pipeline) | Advanced |
| dbt-fabric + git PR workflow | Advanced |
| T-SQL transform procs (read/debug; optional author) | Intermediate |
| Power BI semantic models (rebind, not full report design unless scoped) | Intermediate |
| Azure Key Vault + identity | Intermediate |
| NewStar SPLive/HBLive data models | Intermediate (Title WP) |
| Encompass / mortgage LOS | Basic + discovery (Mortgage WP) |
| IBM Planning Analytics (TM1) feeds | Basic + Finance liaison |

## 3. Backlog themes (prioritized by Green Brick)

Use as sprint input; not a fixed commitment.

| Priority | Theme | D13 outputs |
|---|---|---|
| P0 | Stage/analytics smoke, gap closure, promote hygiene | Runbooks, rebind scripts |
| P1 | Title SM/report sign-off | `title_*` models bound |
| P1 | Finance weekly/monthly sum validation | `sales_sum_*`, `unit_sum_*` |
| P2 | Planning export to TM1 | SUM/HIST export jobs, spec doc |
| P2 | Zonda load unblock (GAP-07) | `pipeline_zonda_load` scheduled in dev |
| P3 | Mortgage Encompass mirror design | raw + transform spike |
| P3 | Purview registration | catalog assets |
| P4 | Web scrape schedule + adapter queue | `web_listing_obt` freshness |
| P4 | BuilderMetrix landing (D18) | `lake_house_buildermetrix` |

## 4. Ways of working

| Topic | Rule |
|---|---|
| **Workspace** | Write to Foundation Development only unless change order |
| **Naming** | D13 enforced in PR review ([doc 03](03-d13-naming-and-data-model.md)) |
| **Git** | All dbt/SQL/automation via Azure DevOps PR; no direct prod edit |
| **Ceremonies** | Biweekly demo; weekly backlog groom |
| **Documentation** | Material changes → `knowledge/` same sprint |
| **Schedules** | Vendor may not enable Fabric schedules without Green Brick written approval |
| **Secrets** | Vendor uses provided KV access; no personal connection strings |

## 5. Roles and rate card (template)

| Role | Responsibilities | Indicative hours/week |
|---|---|---|
| **Fabric architect** | Layer design, pipeline review, promote checklist | 8-16 |
| **dbt analytics engineer** | OBT/DET/SUM models, tests, refresh config | 24-40 |
| **Data engineer** | Transform procs, automation scripts, parity SQL | 16-32 |
| **BI developer** | Semantic model rebind, measure validation | 8-16 |
| **Project manager** | RAID log, sprint board, stakeholder comms | 8-12 |

*(Insert rate caps, overtime rules, travel policy.)*

## 6. Sprint definition of done

A backlog item is **done** when:

1. Code merged to Foundation git main (or release branch).  
2. Deployed to Foundation Development and smoke-tested.  
3. D13 naming verified.  
4. Knowledge or runbook updated if behavior changed.  
5. No open Sev1/Sev2 defects on touched paths.  
6. Parity note attached if transform logic changed.

## 7. KPIs (service level indicators)

| KPI | Target (template) |
|---|---|
| Sprint commitment reliability | >= 85% story points completed |
| P1 defect response | 4 business hours |
| P2 defect response | 1 business day |
| PR review turnaround (vendor) | 1 business day |
| Documentation lag | 0 sprints behind merge |

## 8. In scope services

- Implementation per D13 in Foundation Development  
- Parity analysis vs Enterprise (read-only)  
- Title / Finance / Operations analytics support  
- Discovery docs for Mortgage and TM1  
- Support promote to Foundation prod twin when Green Brick requests  
- Hypercare after major releases (negotiated)

## 9. Out of scope services

Same as [`05-scope-in-scope-out-of-scope.md`](05-scope-in-scope-out-of-scope.md), plus:

- 24/7 production on-call for legacy GBP-Enterprise unless separate NOC contract  
- Business report visual redesign (unless WP added)  
- HR, IAM, or BuildPro application admin  
- TM1 rule authoring inside IBM PA (Finance owns; vendor may feed data only)

## 10. Proposal request (RFS response)

Vendor provides:

1. Rate card by role (USD, 2026)  
2. Minimum engagement length and notice period  
3. Sample sprint plan for first 8 weeks (P0-P1 themes)  
4. Tooling (ADO, Teams, time tracking)  
5. Conflict of interest disclosure  
6. Subcontractor policy  

## 11. Conversion path

Successful RFS may convert to:

- **Fixed-phase RFP** for Mortgage or TM1 after discovery ([`07-rfp-summary.md`](07-rfp-summary.md)), or  
- **Renewed RFS** on quarterly backlog refresh  

## 12. Reference documents

Same appendices as RFP ([`07-rfp-summary.md`](07-rfp-summary.md) section 10).
