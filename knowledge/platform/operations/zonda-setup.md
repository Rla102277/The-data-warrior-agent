# Zonda rebuild into Foundation Development

**Date:** 2026-08-11 (created FD); **promoted to Foundation 2026-08-12**  
**Status:** Live in Foundation Development and Foundation. Schedule OFF;
no data load run. Enterprise sources were not modified (D12).

| FD item | Id |
|---|---|
| `lake_house_zonda` | `4a72e416-a6a1-4ae2-ae6c-e81f20f10cd2` |
| `notebook_zonda_get_credentials` | `cc7de5bc-9375-42de-8faa-068c70373650` |
| `notebook_zonda_community_load` | `dacae8ae-65a4-48df-9fa7-f912f2cac143` |
| `notebook_zonda_plans_load` | `6748930d-3ad2-4602-ae1e-bf595a3a7406` |
| `notebook_zonda_lots_load` | `9b43c58c-b786-4199-a21d-34b2b6434047` |
| `pipeline_zonda_load` | `6152cdbb-8954-46f5-a644-eb3f4fba036b` |

## Source (GBP-Enterprise)

| Item | Role |
|---|---|
| `Zonda` lakehouse | Delta sink: `dbo.community`, `dbo.plans`, `dbo.lots` |
| `nb_get_credentials` | Key Vault `gb-fabric-keyvault` → six `zonda-*` secrets |
| `nb_zonda_*_load` | Zonda Virtual API → overwrite Delta tables |
| `pp_load_zonda_to_fabric` | Notebook orchestrator (no schedule) |
| `act_load_zonda_to_fabric_alerts` | Reflex (deferred; use D6 DL when alerting lands) |

## FD targets (D13)

| Legacy | FD |
|---|---|
| `Zonda` | `lake_house_zonda` (folder `raw`) |
| notebooks | `notebook_zonda_get_credentials`, `notebook_zonda_community_load`, `notebook_zonda_plans_load`, `notebook_zonda_lots_load` (folder `utilities`) |
| pipeline | `pipeline_zonda_load` (folder `utilities`, **schedule OFF**) |

Local defs: `fabric/build/zonda/` (gitignored under `fabric/`). Recreate via
`python3 -u automation/retry_finance_zonda_build.py` (sets `format=ipynb` on
notebooks; without that Fabric returns `PyToIPynbFailure`).

## Credentials

Same Key Vault secrets as Enterprise. FD workspace identity is in
`GB Fabric API Users - Workspace Identities`, but that group (and the WI)
still lack **Key Vault Secrets User** on `gb-fabric-keyvault`. Role assign
blocked for current CLI user; Randy must run the command in
[`identity.md`](identity.md).

## Do not

- Enable a schedule in FD (build-only standing order)
- Run a full load without an explicit off-hours go-ahead (API + Spark write)
- Copy the Reflex until alerting (D6) is wired to
  `foundation_data_monitoring@greenbrickpartners.com`
