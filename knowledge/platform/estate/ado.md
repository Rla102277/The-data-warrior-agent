# Azure DevOps map

**Org:** `https://dev.azure.com/grbk`  
**Captured:** 2026-10-16 via ADO MCP (Confirmed)

## Projects

| Project | ID | Purpose (from description / observation) |
|---|---|---|
| Foundation | `f59add8d-…` | Primary Fabric rebuild engineering repo historically |
| Foundation 2.0 | `e0793eb0-…` | New SDK / Forge Line home |
| TM1 | `98df87db-…` | Separate product |

## Repositories

| Project | Repo | Approx size | URL |
|---|---|---|---|
| Foundation | Foundation | ~37 MB | `https://dev.azure.com/grbk/Foundation/_git/Foundation` |
| Foundation 2.0 | Foundation 2.0 | ~71 KB | `https://dev.azure.com/grbk/Foundation%202.0/_git/Foundation%202.0` |

Local mirrors:

- `~/Documents/Projects/Foundation` — large historical checkout  
- `~/Documents/Projects/Foundation-2.0` — this workspace  

## Pipelines

| Project | Definitions |
|---|---|
| Foundation | **1** — `Jobsite Factory CI` (id 1), created 2026-10-15 by Randy Archambault |
| Foundation 2.0 | **none** |

## Lead note

Two Foundation projects without a written "source of truth" rule will burn time. Foundation 2.0 is the declared rebuild of the engineering platform; the old Foundation repo still holds most Fabric knowledge, dbt, and automation history. Bridge them explicitly; do not silently fork truth.
