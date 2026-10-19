# RFP summary (Request for Proposal)

**Purpose:** Formal competitive procurement for defined Foundation deliverables.  
**Prerequisite:** RFI shortlist or sole-source justification ([`06-rfi-summary.md`](06-rfi-summary.md))

## 1. Title and reference

**Project:** Green Brick Partners Foundation Data Platform  
**Solicitation type:** RFP  
**Reference architecture:** [`02-foundation-development-target.md`](02-foundation-development-target.md)  
**Naming standard:** [`03-d13-naming-and-data-model.md`](03-d13-naming-and-data-model.md)  
**Scope boundary:** [`05-scope-in-scope-out-of-scope.md`](05-scope-in-scope-out-of-scope.md)

## 2. Objectives

The selected vendor will:

1. Extend and stabilize the Foundation Development platform under D13 rules.  
2. Deliver named analytics models (OBT/DET/SUM/HIST) and semantic models per domain roadmap.  
3. Maintain parity evidence against legacy Enterprise where transforms are in scope.  
4. Prepare promotion-ready artifacts for the Foundation deployment pipeline.  
5. Document Title, Finance, and Operations consumption paths; discover Mortgage and TM1 feeds.

## 3. Statement of work (modular work packages)

Vendor proposes hours and price **per package**. Green Brick may award subset.

### WP1: Platform hardening (Required)

| Deliverable | Acceptance |
|---|---|
| Stage orchestrator smoke + runbook update | 16/16 procs SUCCESS on standard run_group |
| Analytics refresh smoke for `p_domain=all` | Published tables match refresh config |
| Rebind scripts verified after promote | Semantic models query Foundation SQL host |
| GAP-07 remediation support (Zonda KV) | Documented steps; load smoke when unblocked |
| Activator / health alert validation | Test email to monitoring DL |

### WP2: Finance and planning feeds (Optional)

| Deliverable | Acceptance |
|---|---|
| Validate `unit_budget_hist`, `sales_sum_monthly`, GL/SGM models | dbt tests + row count baselines |
| Planning export spec (TM1 or successor) | Documented grain, schedule, format |
| Pilot export job (ADLS or agreed channel) | Finance sign-off on sample period |

### WP3: Title presentation (Optional)

| Deliverable | Acceptance |
|---|---|
| `semantic_model_title_booking` parity vs legacy report | Signed checklist by Title stakeholder |
| `title_communities_det` validation | Community counts vs SPLive sample |
| Refresh `p_domain=title` automated in dev | Schedule OFF in prod unless approved |

### WP4: Mortgage discovery and design (Optional)

| Deliverable | Acceptance |
|---|---|
| Encompass source inventory | Tables/APIs, PII classification |
| Target D13 model names (`*_det`, `*_obt`) | Architecture doc in `knowledge/` |
| Mirror + transform spike in FD only | No prod Encompass changes |

### WP5: dbt and analytics expansion (Optional)

| Deliverable | Acceptance |
|---|---|
| New models per approved subject list | Follow OBT/DET/SUM rules |
| `_schema.yml` tests on grain keys | No duplicate grain failures |
| Entry in `analytics_refresh_config` | Materializes to lakehouse |

### WP6: Governance (Optional)

| Deliverable | Acceptance |
|---|---|
| Purview scan registration per [`purview-catalog.md`](../operations/purview-catalog.md) | Assets visible for FD + SQL |
| Lineage spot-check HBLive → transform → analytics | Documented in Purview or knowledge |

## 4. Technical requirements (mandatory compliance)

| # | Requirement |
|---|---|
| R1 | All new artifacts comply with D13 ([doc 03](03-d13-naming-and-data-model.md)) |
| R2 | No writes to GBP-Enterprise, Finance, Operations prod without change order |
| R3 | dbt owns analytics view definitions in repo `dbt/models/analytics/` |
| R4 | Secrets only via Key Vault; no credentials in git |
| R5 | Knowledge updates for material changes under `knowledge/operations/` or `knowledge/external-rfs/` |
| R6 | Deployment via Foundation deployment pipeline only for prod twin |
| R7 | Shapes: use `obt`, `det`, `sum`, `hist`, `map`; ban `dim_`, `fact_`, `vw_` |

## 5. Deliverables list

| # | Deliverable | Format |
|---|---|---|
| D1 | Project plan with milestones | PDF + MS Project or equivalent |
| D2 | Architecture decision records (if new) | Markdown in `knowledge/decisions/` |
| D3 | dbt models + tests | Git PR to Foundation repo |
| D4 | Fabric artifact exports / automation scripts | `automation/` with idempotent deploy |
| D5 | Parity evidence pack | JSON/SQL row counts vs Enterprise |
| D6 | Runbook updates | `knowledge/operations/` |
| D7 | Training session (2h) for Green Brick BI team | Recording + deck |
| D8 | Hypercare period (30 days post-acceptance) | Email support SLA |

## 6. Evaluation criteria

| Criterion | Weight | Notes |
|---|---|---|
| Technical approach | 25% | WP responses, D13 compliance |
| Team qualifications | 20% | Named architects, dbt developers |
| Price | 25% | Total and per-WP transparency |
| Schedule | 15% | Realistic vs dependencies (GAP-07, TM1 docs) |
| References | 15% | Similar Fabric + ERP engagements |

## 7. Proposal format

1. Executive summary (2 pages)  
2. Compliance matrix (R1-R7)  
3. Work package responses with WBS  
4. Staffing plan  
5. Fixed price or T&M with cap  
6. Risk register  
7. Assumptions and exclusions (must align with doc 05)  
8. Three references  

## 8. Commercial terms (template)

*(Green Brick legal to insert: payment milestones, IP ownership of configs, warranty, insurance, background checks, MSA reference.)*

Suggested milestones:

| Milestone | % payment |
|---|---|
| Kickoff + plan approved | 10% |
| WP1 complete | 30% |
| WP2-WP5 per awarded package | per SOW |
| Final acceptance + hypercare start | 20% |
| Hypercare complete | 10% |

## 9. Vendor Q&A

*(Insert portal, deadlines, and rules of engagement.)*

## 10. Appendices for vendors

| Appendix | Content |
|---|---|
| A | [`01-current-architecture.md`](01-current-architecture.md) |
| B | [`02-foundation-development-target.md`](02-foundation-development-target.md) |
| C | [`03-d13-naming-and-data-model.md`](03-d13-naming-and-data-model.md) |
| D | [`04-domain-integration-title-mortgage-planning.md`](04-domain-integration-title-mortgage-planning.md) |
| E | [`../analytics/gold-to-dbt-map.md`](../analytics/gold-to-dbt-map.md) |
| F | [`../rebuild-plan/edw-d13-eval.md`](../rebuild-plan/edw-d13-eval.md) |
