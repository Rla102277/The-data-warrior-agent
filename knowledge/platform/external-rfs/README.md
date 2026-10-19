# External RFS document pack

**Created:** 2026-08-28  
**Audience:** Vendors, integrators, and internal stakeholders responding to or drafting external solicitations  
**Owner:** Green Brick Partners data platform (Foundation program)

This folder is a **read-only briefing pack** for building an **RFI** (Request for Information), **RFP** (Request for Proposal), or **RFS** (Request for Services) related to the Green Brick **Microsoft Fabric** data platform rebuild (**Foundation**).

It summarizes confirmed architecture from the Foundation repository and decision log. It does **not** replace legal procurement templates or signed statements of work.

## How to use

| If you are... | Start here |
|---|---|
| Drafting an RFI (capabilities, questions, market scan) | [`06-rfi-summary.md`](06-rfi-summary.md) |
| Drafting an RFP (scoped deliverables, evaluation criteria) | [`07-rfp-summary.md`](07-rfp-summary.md) |
| Drafting an RFS (services SOW skeleton) | [`08-rfs-summary.md`](08-rfs-summary.md) |
| Setting boundaries for vendors | [`05-scope-in-scope-out-of-scope.md`](05-scope-in-scope-out-of-scope.md) |
| Explaining naming and table shapes (D13) | [`03-d13-naming-and-data-model.md`](03-d13-naming-and-data-model.md) |
| Explaining Title / Mortgage / planning feeds | [`04-domain-integration-title-mortgage-planning.md`](04-domain-integration-title-mortgage-planning.md) |

## Document index

| # | Document | Purpose |
|---|---|---|
| 00 | [`00-overview-and-glossary.md`](00-overview-and-glossary.md) | Program context, glossary, evidence policy |
| 01 | [`01-current-architecture.md`](01-current-architecture.md) | Legacy GBP-Enterprise estate (as-is) |
| 02 | [`02-foundation-development-target.md`](02-foundation-development-target.md) | Foundation Development / Foundation target (to-be) |
| 03 | [`03-d13-naming-and-data-model.md`](03-d13-naming-and-data-model.md) | D13 naming, layers, OBT / DET / SUM / HIST / MAP |
| 04 | [`04-domain-integration-title-mortgage-planning.md`](04-domain-integration-title-mortgage-planning.md) | Title, Mortgage, planning (TM1) interaction model |
| 05 | [`05-scope-in-scope-out-of-scope.md`](05-scope-in-scope-out-of-scope.md) | Explicit in / out of scope |
| 06 | [`06-rfi-summary.md`](06-rfi-summary.md) | RFI boilerplate and question bank |
| 07 | [`07-rfp-summary.md`](07-rfp-summary.md) | RFP structure, deliverables, evaluation |
| 08 | [`08-rfs-summary.md`](08-rfs-summary.md) | RFS / services engagement skeleton |

## Authoritative references (in repo)

| Topic | Path |
|---|---|
| Decision log (D13, D12, D17, ...) | [`../decisions/README.md`](../decisions/README.md) |
| Re-architecture proposal | [`../rebuild-plan/rearchitecture.md`](../rebuild-plan/rearchitecture.md) |
| Gold to dbt map (all domains) | [`../analytics/gold-to-dbt-map.md`](../analytics/gold-to-dbt-map.md) |
| FD analytics setup | [`../operations/analytics-setup.md`](../operations/analytics-setup.md) |
| Deployment pipeline | [`../operations/deployment-pipeline.md`](../operations/deployment-pipeline.md) |
| Agent / naming rules | [`../../AGENTS.md`](../../AGENTS.md) |

## Evidence policy

- **Confirmed:** observed in live Fabric, Azure, or exported SQL/dbt in this repository.  
- **Inferred:** reasonable from names and partial lineage; vendor must validate during discovery.  
- **Planned / open:** recorded in decision log as not yet built.

Do not treat this pack as permission to delete, retire, or cut over production legacy workspaces unless Green Brick provides an explicit written instruction for a named item (decision D12).
