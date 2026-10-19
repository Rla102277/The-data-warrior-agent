# Active Foundation workstreams

Topic map for day-to-day chats. This **expands** Randy’s original repo setup; it does **not** replace it.

## Repo setup (keep / do first — Randy’s baseline)

| Piece | Path |
| --- | --- |
| Canonical agent instructions | [`AGENTS.md`](../../AGENTS.md) |
| Always-on Cursor rules | [`.cursor/rules/`](../../.cursor/rules/) (`no-prod-destroy`, `fabric-architect`, `foundation-naming`) |
| Full agent / IDE setup | [`agent-setup.md`](agent-setup.md) |
| New machine clone (tools, login, verify) | [`developer-environment-clone.md`](developer-environment-clone.md) |
| ADO git | [`ado-git.md`](ado-git.md) |
| Root smoke / clone notes | [`README.md`](../../README.md) |
| Identity / Key Vault patterns | [`identity.md`](identity.md) |
| Analytics / FD standing setup | [`analytics-setup.md`](analytics-setup.md) |
| Deployment pipeline | [`deployment-pipeline.md`](deployment-pipeline.md) |

**Proposal for Randy (approve / expand):** [`foundation-ops-status-randy-2026-10-01.md`](foundation-ops-status-randy-2026-10-01.md) · [PDF](foundation-ops-status-randy-2026-10-01.pdf)  
**How topic chats run:** [`chat-setup.md`](chat-setup.md)  
**Optional review prompt:** [`randy-handoff-prompt.md`](randy-handoff-prompt.md)  
**PDF brief standard:** [`pdf-brief-standard.md`](pdf-brief-standard.md)  
**ROI template (bring your own initiatives):** [`roi-tally.md`](roi-tally.md) · [`roi/README.md`](roi/README.md)  
**M365 / Work IQ portfolio signals (2026-10-14):** [`copilot-initiative-signals-2026-10-14.md`](copilot-initiative-signals-2026-10-14.md) · canvas `copilot-initiative-portfolio`

Single place to find what is in flight. One Cursor chat per row. Stay on `main` for ops unless a product PR needs a branch.

| Topic | Owner | Pack / entry | Chat starter (paste into a new chat) | Status |
| --- | --- | --- | --- | --- |
| BuilderMetrix | Randy | [`buildermetrix-2026-10-01/`](buildermetrix-2026-10-01/README.md) | Continue `knowledge/operations/buildermetrix-2026-10-01/README.md`. Scope: BuilderMetrix MI Link project only (Azure MI, Fortinet/CDW, DNS, prelink, Link). Not general Fabric footprint. | Host prep + Azure prelink dry-run done; DDC Phase2 DH 14-only installed; CDW SEC0587272 still needs reciprocal 5022 + closeout |
| Fabric | Randy | [`fabric-2026-10-01/`](fabric-2026-10-01/README.md) | Continue `knowledge/operations/fabric-2026-10-01/README.md`. Scope: existing Fabric footprint (workspaces, pipelines, identity cutover, BizApps readonly MCP). Not BuilderMetrix MI Link. | Jobs green; P0 connections clean; residual ACL/group + SF OAuth subject opacity |
| TM1 | Randall | [`tm1-2026-10-01/`](tm1-2026-10-01/README.md) | Continue `knowledge/operations/tm1-2026-10-01/README.md`. Scope: TM1 InformXL ready script handoff only. No proc deploy without CM. Not Azure Fortinet/DNS (Infrastructure). Cubewise SGM pack: `cubewise-sgm-handoff-2026-10-07/`. | ODBC ReadyStatus + SQL rewrite packs; Cubewise SGM handoff draft 2026-10-07 |
| SSRS | Randall | [`ssrs-2026-10-01/`](ssrs-2026-10-01/README.md) | Continue `knowledge/operations/ssrs-2026-10-01/README.md`. Scope: SSRS catalog cleanup, KeyReports/GBPReports sproc+CM, SGM, commissions RDLs, Monthly Sales. | Hub status board live; catalog→~55 inventory done; SGM/CM/Monthly Sales/Commissions open |
| SQL DBA | Randall | [`sql-dba-2026-10-01/`](sql-dba-2026-10-01/README.md) | Continue `knowledge/operations/sql-dba-2026-10-01/README.md`. Scope: GBP-SQL03 and GBP-SQL04 DBA (AG, flags, DMK, index, InformXL host jobs/blocks, health, Arc hands-off for SQL). Not MI Link cutover (BuilderMetrix). | SQL03 green; SQL04 RT green; Update_All weekly Sun 08:00 CT |
| Infrastructure | Randall | [`infrastructure-2026-10-01/`](infrastructure-2026-10-01/README.md) | Continue `knowledge/operations/infrastructure-2026-10-01/README.md`. Scope: Azure Arc; Azure TM1 Fortinet NAT / DNS; Entra/AD hygiene (incl. Title Entra Connect); CrowdStrike / Arctic Wolf / Proofpoint / cert-admin risk; Rubrik backup health; Purview eDiscovery; BMX Azure-path observe-first. Not SQL tuning (SQL DBA), not financial file integrations (Integrations), not BuilderMetrix Link cutover, not TM1 ReadyStatus SQL, not SSRS catalog publish. | Arc **13 Connected**; AMA+DCR on **all 13**; Azure TM1 NAT installed; security/backup/Title Entra folded from Work IQ 2026-10-14 |
| Integrations | Randall | [`integrations-2026-10-14/`](integrations-2026-10-14/README.md) | Continue `knowledge/operations/integrations-2026-10-14/README.md`. Scope: Flagstar positive-pay, BlackLine FTP/export, Huntington ACH/Positive Pay, related financial file integrations. Not SQL host DBA, not Infrastructure Arc/Entra/security/Purview. | Pack live 2026-10-14; Huntington evidence under `integrations-huntington-2026-10-07/` |
| Support Desk | Randall | [`support-desk-2026-10-07/`](support-desk-2026-10-07/README.md) | Continue `knowledge/operations/support-desk-2026-10-07/README.md`. Scope: Freshservice tickets and changes via REST API (not MCP). Not SSRS/SQL catalog, not Cursor seat packaging (AI Enablement). | REST helper + `freshservice-api` rule; MCP removed; hours on ROI hub under Support Desk |
| AI Enablement | Randall | [`ai-enablement-2026-10-07/`](ai-enablement-2026-10-07/README.md) | Continue `knowledge/operations/ai-enablement-2026-10-07/README.md`. Scope: Cursor/Claude seat packaging, Cursor tools app (`cursor-addons`), Biz Apps RO MCP, PC setup. Claude Enterprise plan is PARKED. Not Support Desk ticket queue. | Cursor tools app on main (`e7a3ebc`); spin Randy/Chelsey/Patrick; Claude Enterprise parked |
| Management | Randall | [`management-2026-10-07/`](management-2026-10-07/README.md) | Continue `knowledge/operations/management-2026-10-07/README.md`. Scope: private Hub routing / personal ops. FY2025 SOX/SOD → private **Audit** chat (`Documents/Projects/Audit`). Not Foundation SQL/SSRS/Fabric/TM1/Infra/Integrations/Support Desk/AI Enablement packaging. | Hub initiative **Management**; Audit = private hub `Audit/` |
| Power Apps | Randall | [`power-platform-inventory-2026-10-10/`](power-platform-inventory-2026-10-10/README.md) | Continue `knowledge/operations/power-platform-inventory-2026-10-10/README.md`. Scope: GBP-Dev / GBP-Prod Power Apps, Dataverse apps, CustSat / TCB / CA / QDT solutions and flows. Not Fabric CustSat analytics (Fabric) unless explicitly joined. | Dataverse MCP wired (gbpdev/gbpprod); inventory + CustSat scan; canvas `power-apps-progress` |

## Rules of thumb

- Randy’s baseline setup (`AGENTS.md`, `.cursor/rules`, `agent-setup.md`, `developer-environment-clone.md`) stays required; topics only organize chats.
- Shared truth is the pack README, not chat history.
- **BuilderMetrix** = MI Link project. **Fabric** = existing Fabric estate. **SQL DBA** = SQL03 + SQL04.
- **Integrations** = Flagstar / BlackLine / Huntington financial file transfers. **Infrastructure** includes CrowdStrike, Arctic Wolf, Proofpoint, Rubrik, Title Entra Connect, Purview eDiscovery.
- **FY2025 SOX/SOD** = private **Audit** chat (`Documents/Projects/Audit`), not a Foundation ACTIVE row.
- Do not create separate repos or projects for these topics.
- Branch only for reviewable product code (dbt, pipelines). Ops docs land on `main`.
- Never commit `automation/mcp_onprem_sql/.env`.
