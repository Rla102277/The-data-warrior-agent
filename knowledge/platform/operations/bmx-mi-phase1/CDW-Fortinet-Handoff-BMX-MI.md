# Fortinet requirements — Azure SQL Managed Instance Link (sqlmi-bmx-prod)

**To:** CDW / Fortinet engineer  
**From:** Randall Anderson, Green Brick Partners  
**Date:** 2026-10-01  
**Scope:** Firewall + routing + IPSec Phase 2 only. Do not change SQL Server or Azure SQL MI configuration.

---

## Topology

- Site-to-site is **FortiGate ↔ FortiGate** (no Azure VPN Gateway).
- Azure FortiGate: `GBPI-GBP-fgt01` (West US 3 hub), internal next hop **`10.1.2.4`**
- On-prem SQL host: **GBP-SQL03** (SQL VLAN)
- MI subnet: **`10.3.8.0/24`** (`snet-sqlmi-bmx` on `gbpartner-vnet-wus3-prod`)
- MI private IP / FQDN: **`10.3.8.9`** / `sqlmi-bmx-prod.5936f2453345.database.windows.net` (private only)

TCP **1433** and **5022** from GBP-SQL03 → MI already succeed in testing. Inventory existing policy first; close gaps only.

---

## Required firewall rules

Do **not** allow Internet, `Any`, or `0.0.0.0/0`. Prefer host/SQL VLAN ↔ `10.3.8.0/24` only.

| Direction | Source | Destination | Ports | Action |
|-----------|--------|-------------|-------|--------|
| Azure → on-prem | `10.3.8.0/24` | GBP-SQL03 (or SQL VLAN) | TCP **5022** | Allow |
| On-prem → Azure | GBP-SQL03 (or SQL VLAN) | `10.3.8.0/24` | TCP **5022**, **1433**, **11000–11999** | Allow |

Fallback on-prem prefixes if host-level scoping is not possible: `172.16.0.0/12`, `10.10.0.0/16` (existing hub UDR corp ranges). Do not widen Azure side beyond `10.3.8.0/24` unless required for return-path troubleshooting.

---

## Required routing checks

1. Azure FortiGate can reach `10.3.8.0/24` via hub→spoke (forwarded peering).
2. MI subnet return path to on-prem uses next hop **`10.1.2.4`** (route table `rt-sqlmi-bmx-to-onprem` — verify not overridden).
3. On-prem FortiGate routes/policies allow return traffic from `10.3.8.0/24` to GBP-SQL03.
4. No asymmetric allow/deny on TCP **5022**.

---

## Required — IPSec Phase 2 rekey alignment

1. Export Phase 2 SA lifetime (seconds and/or KB) on **Azure** FortiGate for the corporate S2S tunnel.
2. Export Phase 2 lifetime/rekey on **on-prem** FortiGate for the **same** tunnel.
3. Set **both** ends to identical Phase 2 values.
4. Capture before/after evidence.
5. Optional: coordinated rekey test in a low-risk window before Link go-live.

---

## Return to Green Brick

- Phase 2 values before/after (both FortiGates)
- Confirmation section firewall rules are present (or already were)
- Change ticket ID, implementer, date/time
- Notify Randall Anderson when complete
