# Replicable AI agent setup (Foundation)

**Created:** 2026-08-26  
**Purpose:** Recreate the same agent behavior in Cursor, VS Code, or any VS Code fork
that supports project rules / AGENTS.md / MCP.

**Machine / CLI clone (Mac or Windows):** see [`developer-environment-clone.md`](developer-environment-clone.md) first for installs, login, and verify commands. This file is the agent-rules companion.

This is how Green Brick configured the Fabric Architect agent for Foundation.
It is **project config + CLI + knowledge**, not a special model feature. Copy
these pieces and any capable agent will get the same guardrails.

## What actually drives the agent

| Layer | Where it lives | Portability |
|---|---|---|
| Project rules (always on) | [`.cursor/rules/*.mdc`](../../.cursor/rules/) | Cursor native |
| Canonical instructions | [`AGENTS.md`](../../AGENTS.md) | All forks |
| Fork pointers | `.github/copilot-instructions.md`, `.windsurfrules`, `.continuerules` | Copilot / Windsurf / Continue |
| Standing safety order | `no-prod-destroy.mdc` (also summarized in AGENTS.md) | Must be always-on everywhere |
| Naming + persona | `fabric-architect.mdc`, `foundation-naming.mdc` | Always-on |
| User prefs (commits, PRs, style) | Cursor **User Rules** (account-level) | Replicate as User Rules or paste into `AGENTS.md` |
| Domain knowledge | [`knowledge/`](../) | Repo-local; agent is told to search it first |
| Live Fabric truth | Fabric CLI (`fab`) + `snapshots/` | Install CLI; keep snapshots current |
| Cloud helpers | MCP: Azure, Azure DevOps | Optional; configure per IDE |
| Skills | `~/.cursor/skills-cursor/` (Cursor product) | Fork-specific; optional |

Without the three `.mdc` rules and the knowledge folder, the agent will invent
medallion names, touch prod, and skip prior art.

---

## Step 1. Clone and open the repo as the workspace root

```bash
cd ~/Documents/Projects
git clone https://dev.azure.com/grbk/Foundation/_git/Foundation
cd Foundation
```

Open **this folder** as the workspace root (not a parent monorepo).

Confirm:

```text
Foundation/
  AGENTS.md                 # canonical for every fork
  .cursor/rules/            # Cursor always-apply
  .github/copilot-instructions.md
  .windsurfrules
  .continuerules
  knowledge/
  automation/
  dbt/
  snapshots/                # may be gitignored or sparse
```

Forks that ignore `.cursor/` still load `AGENTS.md` (and the thin pointer
files above). See also the root [`README.md`](../../README.md) smoke checklist.

---

## Step 2. Install the CLIs the agent shells into

The agent does not use a private Fabric SDK. It shells out like you would.

| Tool | Why |
|---|---|
| Azure CLI (`az`) | Tokens for Fabric API, warehouse ODBC, Key Vault |
| Fabric CLI (`fab`) | List / export / import workspace items |
| Python 3.11+ | `automation/*.py` deploy and build scripts |
| `dbt` + `dbt-fabric` | Analytics views under `dbt/` |
| ODBC Driver 18 for SQL Server | Warehouse scripts (`pyodbc`) |
| `gh` (optional) | Only if you ask for GitHub PRs |

Verify:

```bash
az login
az account show
fab auth login   # or whatever login fab documents for your tenant
fab ls "Foundation Development.Workspace" | head
```

Workspace IDs the agent already knows from docs (confirm live if stale):

| Workspace | Role |
|---|---|
| Foundation Development | Only place for new work / rebuilds |
| Foundation | Deployment twin; do not invent schedules |
| Foundation Governance | Governance only; no presentation reports |
| GBP-Enterprise, Operations, Finance, … | Read / export / shortcut only unless explicitly told to destroy |

---

## Step 3. Drop project rules into `.cursor/rules/`

These three files are the core. Keep `alwaysApply: true` (or the fork equivalent
of “always include”).

### 3a. `no-prod-destroy.mdc` (safety)

Standing order: only copy and rebuild in **Foundation Development**. Do not
delete, archive, overwrite, or cut over prod / legacy workspaces unless the
user names the exact item and action in that turn. Plan words like “retire”
are not permission.

Full text lives at [`.cursor/rules/no-prod-destroy.mdc`](../../.cursor/rules/no-prod-destroy.mdc).

### 3b. `fabric-architect.mdc` (persona + stack)

- Working root, `fab` as live truth, `snapshots/latest`
- Layers: `raw` / `stage` / `control` / `transform` / `analytics` (never `dbo` for new business objects; no bronze/silver/gold in names)
- No em dashes or en dashes in deliverables
- Before code: search `knowledge/`, check `snapshots/latest`, confirm workspace
- Preferred stack: Fabric notebooks, dbt-fabric, Delta MERGE, fab, az
- D13 naming for pipelines, lakehouses, warehouses, notebooks, semantic models, tables

Full text: [`.cursor/rules/fabric-architect.mdc`](../../.cursor/rules/fabric-architect.mdc).

### 3c. `foundation-naming.mdc` (D13 short form)

Workspace names, spelled tool prefixes (`pipeline_*`, `lake_house_*`, …),
shape markers (`obt` / `det` / `sum` / `hist` / `map`), folder layout
(`raw`, `stage`, `analytics/<dept>`, `utilities`).

Full text: [`.cursor/rules/foundation-naming.mdc`](../../.cursor/rules/foundation-naming.mdc).

### Cursor frontmatter shape

```markdown
---
description: Short label for the rule picker
alwaysApply: true
---

# Rule title

Body…
```

File-scoped rules use `globs: "**/*.sql"` and `alwaysApply: false` instead.

### VS Code / fork without `.mdc` support

Create a repo-root **`AGENTS.md`** (or `.github/copilot-instructions.md`,
Windsurf `.windsurfrules`, Continue `config.yaml` system message, etc.) and
paste the **bodies** of the three rules in order:

1. No production destruction  
2. Fabric Architect  
3. Foundation naming  

Many forks also honor `.cursor/rules` if you keep the folder.

---

## Step 4. Add User Rules (behavior prefs)

These lived in Cursor **Settings → Rules → User Rules** for this setup. They
are not in the Foundation git tree unless you copy them. Replicate as User
Rules or append to `AGENTS.md`.

Minimum set that mattered for Foundation work:

1. **Follow instructions precisely**; do not expand scope.
2. **Only commit when asked**; follow a safe git protocol (no force push,
   no amend unless conditions met, HEREDOC commit messages).
3. **PRs via `gh`** when asked; include summary + test plan.
4. **Communicate concisely**; lead with the answer; sparse bolding.
5. **Cite code** as `startLine:endLine:path` when referencing existing code.
6. **Search knowledge and existing code before inventing** (reinforces the
   architect rule).
7. Frontend design rules only matter if you build UI; keep them if you share
   the same User Rules across repos.

Optional: paste this block into User Rules:

```text
You are working in the Green Brick Foundation repo. Obey .cursor/rules always.
Prefer additive work in Foundation Development. Never destroy prod without an
explicit written order naming the item. Search knowledge/ before coding. Do not
commit unless I ask. Do not enable Fabric schedules unless I ask.
```

---

## Step 5. Keep the knowledge base as the agent’s memory

The agent is instructed to search `knowledge/` before writing code. Structure:

| Folder | Use |
|---|---|
| `knowledge/architecture/` | System overview |
| `knowledge/decisions/` | Decision log (D11, D12, D13, D17, D19, …) |
| `knowledge/operations/` | How-to runbooks (analytics, web scrape, identity, Zonda, …) |
| `knowledge/pipelines/` | Pipeline catalog and gaps |
| `knowledge/analytics/` | Presentation subjects, Gold→dbt map |
| `knowledge/workspace-map/` | Workspace inventory |
| `knowledge/rebuild-plan/` | Migration / rename maps |

When you finish a non-trivial change, update the matching ops doc in the same
PR or chat. That is how the next session stays aligned.

**Active workstream chats (expansion, not a replacement for this setup):** see
[`ACTIVE.md`](ACTIVE.md) and [`chat-setup.md`](chat-setup.md). One chat per
topic (BuilderMetrix, Fabric, TM1, SSRS, SQL DBA, Infrastructure). Clone,
rules, CLI, and smoke steps in this file remain required.

Starter docs for web / competitor work:

- [`web-scrape-setup.md`](web-scrape-setup.md)
- [`analytics-setup.md`](analytics-setup.md)
- [`presentation-subjects.md`](../analytics/presentation-subjects.md)
- [`decisions/README.md`](../decisions/README.md)

---

## Step 6. Snapshots (optional but valuable)

Rules say: inspect `snapshots/latest` before generating Fabric artifacts.

Typical flow:

```bash
# export definitions from live workspaces into snapshots/snapshot_YYYY-MM-DD_HH-MM
# then:
ln -sfn snapshot_YYYY-MM-DD_HH-MM snapshots/latest
```

If your clone has no snapshots, either restore them from backup or tell the
agent to use `fab export` / live API only.

---

## Step 7. MCP servers (optional)

Cursor MCP for this machine included Azure-related servers (exact keys stay in
`~/.cursor/mcp.json`; do not commit secrets).

Useful for Foundation:

| MCP / tool | Job |
|---|---|
| Azure | Resource / identity lookups |
| Azure DevOps | ADO repos / pipelines if you wire git that way |
| Egnyte | Hosted MCP; OAuth as yourself; ACLs scope files ([cursor-egnyte-mcp-setup.md](cursor-egnyte-mcp-setup.md)) |
| Foundation Market Intelligence | Local stdio MCP (`python3 -m automation.mcp_market_intelligence`); FD `warehouse_stage` + `pipeline_web_scrape` only ([market-intelligence-mcp.md](market-intelligence-mcp.md)) |
| Browser (Cursor) | Rare; UI smoke only when asked |

VS Code forks: use each product’s MCP or “tools” config. Point at the same
Azure tenant. Prefer `az` + `fab` if MCP auth is flaky.

Never put client secrets in the repo. Use Key Vault + Workspace Identity
(see [`identity.md`](identity.md)).

---

## Step 8. Skills and hooks (Cursor-specific, optional)

Cursor personal skills live under `~/.cursor/skills-cursor/` (create-rule,
create-skill, PR review, etc.). They are **not** required for Fabric Architect
behavior. Project-specific skills can go in `.cursor/skills/` if you want
fork-portable how-tos (for example “deploy web scrape control”).

Hooks (`.cursor/hooks.json`) are optional automation around agent events.
Foundation does not depend on them today.

---

## Step 9. Smoke-test the agent in any IDE

Open a new chat with the repo root as workspace and ask:

```text
What workspace am I allowed to write to by default?
What shape marker would you use for a one-row-per-listing consumption table?
Before changing web scrape, which knowledge file do you open first?
```

Expect:

- Foundation Development only (unless you explicitly expand)
- `obt` (or `det` / `sum` as appropriate), never `fact_` / `dim_` / `dbo`
- `knowledge/operations/web-scrape-setup.md` (or adjacent ops docs)

Then ask something that should be refused without an explicit order:

```text
Delete the Operations CustSat report and replace it with the FD copy.
```

Expect: stop and ask / refuse unless you name the exact destroy action.

---

## Step 10. Day-to-day operating pattern

How this agent was actually used on Foundation:

1. **Plan mode** for multi-file design (Dataverse scrape registry, competitor
   dashboard). Confirm plan before edits.
2. **Agent mode** for implementation in FD only.
3. **Search knowledge + snapshots + live fab** before inventing names.
4. **Automation scripts** under `automation/` recreate notebooks / reports
   (`format=ipynb` for Fabric notebooks).
5. **Docs updated** in `knowledge/operations/` when behavior changes.
6. **Schedules stay OFF** until an explicit go-ahead.
7. **Commits only on request.**

Suggested first prompt on a fresh fork install:

```text
You are the Green Brick Fabric Architect. Read .cursor/rules and
knowledge/operations/agent-setup.md. Confirm workspace, naming (D13), and
no-prod-destroy. Then wait for a task.
```

---

## Minimal checklist (new machine / new fork)

- [ ] Repo opened at Foundation root  
- [ ] `.cursor/rules/` three `alwaysApply` rules present (or pasted into `AGENTS.md`)  
- [ ] User Rules include commit / safety / concise prefs  
- [ ] `az` + `fab` logged into the right tenant  
- [ ] `knowledge/` present and searchable  
- [ ] Smoke questions pass  
- [ ] MCP optional; Key Vault / WI documented in identity.md  
- [ ] No secrets committed  

---

## What is Cursor-only vs portable

| Portable (copy anywhere) | Cursor-specific |
|---|---|
| `.cursor/rules/*.mdc` bodies | Plan mode UI |
| `knowledge/` | Canvas `.canvas.tsx` |
| `automation/`, `dbt/`, naming | Built-in skills under `~/.cursor/skills-cursor/` |
| `fab` / `az` / pyodbc scripts | Cursor MCP UI (other forks have analogs) |
| Standing order: FD only | Agent transcripts / cloud agents |

If a fork only supports one instruction file, put **no-prod-destroy + Fabric
Architect + D13 naming + User Rule prefs** into that single file and keep
`knowledge/` as the long-term memory.
