# Foundation architecture overview

**Status:** Binding decisions Confirmed in `knowledge/decisions/README.md`.  
**Rebuild package status:** Core SDK and policy engine implemented in this repository rebuild branch.  
**Do not read this document as proof that every target module is already deployed to Fabric.**

## Product

Foundation is the Green Brick Partners enterprise Data and AI platform. Fabric is the primary execution plane. Azure provides identity, networking, Key Vault, and supporting services. Azure DevOps is the delivery system of record.

## Workspaces

| Workspace | Role |
|---|---|
| Foundation Development | Primary engineering and validation |
| Foundation | Production twin |
| Foundation Governance | Governance and inventory only (D17) |
| Legacy estates | Read within approved scope; no unauthorized mutation (D12) |

## Layers

`raw` -> `stage` -> `control` -> `transform` -> `analytics`

Do not replace these names with bronze/silver/gold for new work.

## Package ownership (rebuild)

| Layer | Owns |
|---|---|
| `foundation/` | Stable SDK: models, policies, evidence, discovery interfaces, CLI |
| `discovery/` | Parsers and inventory adapters (ADF, Fabric fixtures, later SQL/dbt) |
| `engineering/` | Ingestion/quality/contracts/reconciliation engines |
| `platform/` | Fabric/Azure deployment manifests and platform policies |
| `jobsite/` | Existing factory runtime (retained; absorbs into Foundation branding over time) |
| `automation/` | Operational scripts (retained) |
| `dbt/` | Analytics project `foundation` |
| `control/` | Future control-plane schema migrations (evaluate existing warehouse_stage control tables first) |
| `rebuild/` | Migration evidence and execution ledger |

## Security boundaries

- Agents may design and generate; they cannot approve their own production releases.
- Policy engine defaults to DENY when authorization is unclear.
- Importing Foundation modules never authenticates or mutates cloud resources.
