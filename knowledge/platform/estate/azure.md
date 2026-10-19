# Azure estate (around Fabric)

**Captured:** 2026-10-16  
**Default subscription:** Production-Fabric `ef9cbd96-c21e-4800-a898-fee8914dd532`  
**Tenant:** `e4a6f415-d627-4422-b4d5-39090a5a4486`

## Subscriptions (Confirmed)

| Name | ID | Default |
|---|---|---|
| Production-Fabric | `ef9cbd96-c21e-4800-a898-fee8914dd532` | yes |
| Azure subscription 1 | `55028f70-3ddc-468a-913d-55d258596917` | no |
| Platform | `34694550-0f62-4591-9d9d-26bd60fdf5a1` | no |
| Non Production | `a3c22a80-aac0-4567-8c50-b7ac9809d767` | no |
| Production | `e83d955f-14df-45e8-a7a3-83f146096a17` | no |

Non Production sample RGs seen: `gbpartner-vnet-nonprod`, `NetworkWatcherRG` (shallow pass only).

## Production-Fabric resource groups (Confirmed)

| RG | Location | Notes |
|---|---|---|
| `rg-gbpartner-fabric` | westus3 | Fabric capacity, Key Vault, integration storage, export Function |
| `rg-wus3-data` | westus3 | Data plane (not fully enumerated) |
| `rg-wus3-network` | westus3 | Network |
| `rg-gbpartner-tm1` | westus3 | TM1 |
| `rg-bmx-sqlmi-wus3` | westus3 | BuilderMetrix SQL MI |
| `gbpartner-asc-export` | southcentralus | ASC export |
| `DefaultResourceGroup-SCUS` | southcentralus | Default |
| `VisualStudioOnline-…` | centralus | DevOps related |
| `NetworkWatcherRG` | westus3 | Watcher |

## rg-gbpartner-fabric resources (Confirmed)

| Resource | Type |
|---|---|
| `gbpwus3fabric01` | Microsoft.Fabric/capacities — **F64**, Active, West US 3 |
| `gb-fabric-keyvault` | Key Vault |
| `GBP-nsg-Fabric` | NSG |
| `gbpintegrationfiles` | Storage (southcentralus) |
| `stfoundationexport` | Storage (southcentralus) |
| `func-foundation-paginated-export` | Function App + App Insights |

## Capacity admins (from legacy environment.md, not re-verified this pass)

Listed historically: ppurviance, randerson, automations, bcorbet, rarchambault (GreenBrick1 / greenbrickpartners UPNs). Treat as **Inferred until re-checked** in Fabric admin portal.
