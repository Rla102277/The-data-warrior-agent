# Developer environment clone (Windows or Mac)

**Audience:** New Green Brick developer cloning Foundation on a fresh machine  
**Updated:** 2026-09-17  
**Goal:** One checklist: every tool, every install command, every login, every verify step.

This file is the **machine + CLI** clone guide. Agent / IDE guardrails are summarized here and detailed in [`agent-setup.md`](agent-setup.md).

---

## 0. Access you need before day one

Ask your admin if you do not already have:

| Access | Why |
|---|---|
| Azure AD / Entra account in the Green Brick tenant | `az login`, Fabric, warehouse ODBC |
| Azure DevOps (`dev.azure.com/grbk`) read on project **Foundation** | `git clone` |
| Microsoft Fabric access to **Foundation Development** | Live work (`fab`, pipelines, lakehouses) |
| Optional: Key Vault Secrets User on `gb-fabric-keyvault` | Zonda / scrape secrets (not required for read-only clone) |
| Optional: Cursor or VS Code license | IDE with agent rules |

**Standing order:** only write / rebuild in **Foundation Development**. Do not destroy prod or legacy workspaces. See [`.cursor/rules/no-prod-destroy.mdc`](../../.cursor/rules/no-prod-destroy.mdc).

---

## 1. Install base tools

Pick your OS section. Install everything in that section before cloning.

### 1a. macOS

```bash
# Homebrew (if missing)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Core CLIs
brew install git azure-cli python@3.12 powershell
brew install --cask microsoft-odbc-driver-18-for-sql-server

# Fabric CLI (Microsoft package)
pip3 install ms-fabric-cli
# If that package name fails on your date, use current Microsoft docs for "Fabric CLI" install:
#   https://learn.microsoft.com/en-us/fabric/data-engineering/get-started-fabric-cli

# Optional but useful
brew install gh node
```

### 1c. Linux (Ubuntu 24.04, including Cursor Cloud Agents)

```bash
bash automation/cloud_agent_install.sh
source .venv/bin/activate
cd dbt && dbt parse
```

The script installs Azure CLI, ODBC Driver 18, PowerShell 7, Fabric CLI, dbt, and pyodbc into a repo-root `.venv`. The paginated export API uses `automation/paginated_export_api/.venv` because its pinned packages conflict with current dbt-fabric and ms-fabric-cli. The script copies `dbt/profiles.yml.example` to `~/.dbt/profiles.yml` only when that file is missing. `dbt parse` does not need a warehouse login. Live Fabric work still needs `az login` and `fab auth login`.

Apple Silicon note: after Homebrew install, follow the brew “Next steps” to put `/opt/homebrew/bin` on your `PATH`.

### 1b. Windows (PowerShell as Administrator where noted)

```powershell
# Winget (ships with modern Windows 11). If missing, install App Installer from Microsoft Store.

# Core
winget install --id Git.Git -e
winget install --id Microsoft.AzureCLI -e
winget install --id Python.Python.3.12 -e
winget install --id Microsoft.PowerShell -e
winget install --id Microsoft.msodbcsql.18 -e

# Fabric CLI
py -3 -m pip install --upgrade pip
py -3 -m pip install ms-fabric-cli

# Optional
winget install --id GitHub.cli -e
winget install --id OpenJS.NodeJS.LTS -e
```

Close and reopen the terminal after installs so `PATH` refreshes.

Chocolatey alternative (if your machine uses choco instead of winget):

```powershell
choco install git azure-cli python312 powershell-core
# ODBC Driver 18: use winget or Microsoft download MSI
```

---

## 2. Confirm CLIs exist

### macOS / Linux shell

```bash
git --version
az version
python3 --version          # need 3.11+
pwsh --version             # PowerShell 7
fab --help                 # Fabric CLI
odbcinst -q -d             # should list "ODBC Driver 18 for SQL Server"
```

### Windows PowerShell

```powershell
git --version
az version
py -3 --version
pwsh --version
fab --help
Get-OdbcDriver | Where-Object Name -like "*18*"
```

---

## 3. Clone the repo

### macOS

```bash
mkdir -p ~/Documents/Projects
cd ~/Documents/Projects
git clone https://dev.azure.com/grbk/Foundation/_git/Foundation
cd Foundation
```

### Windows

Use **OneDrive Documents** (Green Brick), not local `C:\Users\<you>\Documents`.

```powershell
$docs = $null
foreach ($c in @(
  $(if ($env:OneDriveCommercial) { Join-Path $env:OneDriveCommercial 'Documents' }),
  $(if ($env:OneDrive) { Join-Path $env:OneDrive 'Documents' }),
  (Join-Path $env:USERPROFILE 'OneDrive - Green Brick Partners\Documents')
)) {
  if ($c -and (Test-Path -LiteralPath $c)) { $docs = $c; break }
}
if (-not $docs) { throw 'OneDrive Documents not found. Sign in to OneDrive and retry.' }
New-Item -ItemType Directory -Force -Path (Join-Path $docs 'Projects') | Out-Null
Set-Location (Join-Path $docs 'Projects')
git clone https://dev.azure.com/grbk/Foundation/_git/Foundation
Set-Location Foundation
```

**ADO auth:** sign in when Git Credential Manager prompts, or use an ADO PAT with Code Read. Details: [`ado-git.md`](ado-git.md).

Open **this folder** as the IDE workspace root (not a parent monorepo).

Expected top-level:

```text
Foundation/
  AGENTS.md
  README.md
  .cursor/rules/
  knowledge/
  automation/
  dbt/
  snapshots/          # often empty or gitignored locally
```

---

## 4. Python virtualenv + packages

Always use a venv so dbt / pyodbc do not fight system Python.

### macOS

```bash
cd ~/Documents/Projects/Foundation
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip

# dbt analytics
python -m pip install -r dbt/requirements.txt

# warehouse / automation scripts
python -m pip install pyodbc

# optional: local Playwright scrape heal
python -m pip install playwright
playwright install chromium

# optional: local analysis (pandas / numpy / pypdf / matplotlib)
python -m pip install -r requirements-analysis.txt

# optional: paginated export API local smoke
python -m pip install -r automation/paginated_export_api/requirements.txt
```

### Windows

```powershell
Set-Location (Join-Path $env:OneDriveCommercial 'Documents\Projects\Foundation')
# If OneDriveCommercial is empty: Join-Path $env:USERPROFILE 'OneDrive - Green Brick Partners\Documents\Projects\Foundation'
py -3 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip

python -m pip install -r dbt\requirements.txt
python -m pip install pyodbc

# optional
python -m pip install playwright
playwright install chromium

# optional local analysis (pandas / numpy / pypdf / matplotlib)
python -m pip install -r requirements-analysis.txt

python -m pip install -r automation\paginated_export_api\requirements.txt
```

If PowerShell blocks script activation:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Keep `.venv/` out of git (already gitignored). Reactivate each new shell:

| OS | Command |
|---|---|
| Mac | `source .venv/bin/activate` |
| Windows | `.\.venv\Scripts\Activate.ps1` |

---

## 5. dbt profile

```bash
# Mac / Windows (Git Bash)
cd dbt
cp profiles.yml.example ~/.dbt/profiles.yml
```

Windows PowerShell:

```powershell
cd dbt
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.dbt" | Out-Null
Copy-Item profiles.yml.example "$env:USERPROFILE\.dbt\profiles.yml"
```

Edit `~/.dbt/profiles.yml` if your example needs host / database names. Target warehouse is **`warehouse_stage`** in Foundation Development. Auth is Azure CLI (`az login`), not a SQL password.

```bash
# with venv active
cd dbt
dbt debug
```

If ODBC Driver 18 is missing or `dbt debug` fails, use the sql-runner fallback later (`dbt/deploy_via_sql_runner.sh`) instead of blocking onboarding.

---

## 6. Azure + Fabric login

```bash
az login
az account show
# Confirm subscription / tenant are Green Brick. Switch if needed:
# az account list -o table
# az account set --subscription "<name-or-id>"

fab auth login
fab ls "Foundation Development.Workspace"
```

Windows: same commands in PowerShell after `az` and `fab` are on `PATH`.

Useful IDs (confirm live if stale):

| Workspace | Role |
|---|---|
| Foundation Development | **Only** place for new write / rebuild work |
| Foundation | Deployment twin; do not invent schedules |
| Foundation Governance | Governance only; no presentation reports |
| GBP-Enterprise, Operations, Finance | Read / export / shortcut unless explicitly ordered |

FD SQL host (warehouse / lakehouse SQL endpoint family):

```text
cx2knzbh2yrejngvheequwseqy-mqufaqgon22utad7n56bdunt4e.datawarehouse.fabric.microsoft.com
```

Databases you will hit most: `warehouse_stage`, `lake_house_analytics`.

---

## 7. IDE (Cursor recommended)

1. Install [Cursor](https://cursor.com) (or VS Code + Copilot).
2. **File → Open Folder** → the `Foundation` repo root.
3. Confirm these exist (they ship in git):
   - `AGENTS.md`
   - `.cursor/rules/no-prod-destroy.mdc`
   - `.cursor/rules/fabric-architect.mdc`
   - `.cursor/rules/foundation-naming.mdc`
4. Optional User Rule (Cursor Settings → Rules):

```text
You are working in the Green Brick Foundation repo. Obey .cursor/rules always.
Prefer additive work in Foundation Development. Never destroy prod without an
explicit written order naming the item. Search knowledge/ before coding. Do not
commit unless I ask. Do not enable Fabric schedules unless I ask.
```

5. Optional MCP (Azure / Azure DevOps) via Cursor MCP settings. Prefer `az` + `fab` if MCP auth is flaky. Never commit secrets. See [`identity.md`](identity.md).

Full agent replication: [`agent-setup.md`](agent-setup.md).

---

## 8. Day-one verify (must pass)

Run with venv active and `az` / `fab` logged in.

### Shell verify

```bash
# Mac path example; Windows: OneDrive Documents\Projects\Foundation (not local Documents)
cd ~/Documents/Projects/Foundation
source .venv/bin/activate   # Windows: .\.venv\Scripts\Activate.ps1

az account show --query "{user:user.name, tenant:tenantId}" -o json
fab ls "Foundation Development.Workspace" | head
python -c "import pyodbc; print('pyodbc ok')"
dbt --version
```

### Warehouse token smoke (optional)

```bash
python - <<'PY'
import struct, subprocess, pyodbc
HOST = (
    "cx2knzbh2yrejngvheequwseqy-mqufaqgon22utad7n56bdunt4e"
    ".datawarehouse.fabric.microsoft.com"
)
tok = subprocess.check_output([
    "az", "account", "get-access-token",
    "--resource", "https://database.windows.net/",
    "--query", "accessToken", "-o", "tsv",
], text=True).strip()
tb = tok.encode("utf-16-le")
ts = struct.pack(f"<I{len(tb)}s", len(tb), tb)
cn = pyodbc.connect(
    f"Driver={{ODBC Driver 18 for SQL Server}};Server={HOST};"
    "Database=warehouse_stage;Encrypt=yes",
    attrs_before={1256: ts},
)
cur = cn.cursor()
cur.execute("SELECT TOP 1 name FROM sys.tables")
print("warehouse_stage ok", cur.fetchone())
cn.close()
PY
```

### Agent smoke (in IDE chat)

Ask:

1. Which workspace may you write to by default? → **Foundation Development**
2. Shape marker for one-row-per-listing consumption? → **`obt`**
3. Delete an Operations report without an explicit destroy order? → **refuse / ask**

---

## 9. Commands you will run constantly

Activate venv first.

| Task | Command |
|---|---|
| Azure token refresh | `az login` (or `az account get-access-token`) |
| Fabric login | `fab auth login` |
| List FD workspace | `fab ls "Foundation Development.Workspace"` |
| dbt analytics (preferred) | `cd dbt && dbt run --select analytics` |
| dbt via sql runner fallback | `bash dbt/deploy_via_sql_runner.sh <model> ...` |
| Analytics → lakehouse publish | Start `pipeline_operations_analytics_refresh` with `p_domain=operations` (or `all`) in Fabric UI / API; schedules stay OFF unless asked |
| Market Intelligence rebuild | `python automation/build_market_intelligence_report.py` |
| Market Intelligence smoke | `python automation/run_market_intelligence_mvp_smoke.py` |
| Web scrape heal (example) | `python -u automation/run_web_scrape_strategic_heal.py` |
| Seed community geo | `python -u automation/seed_web_community_geo.py` |

Windows note: prefer `bash dbt/deploy_via_sql_runner.sh` from Git Bash, or run the same script under WSL. Pure PowerShell can call `bash` if Git Bash is installed.

---

## 10. Tool inventory (complete list)

| Tool | Required? | Mac install | Windows install | Used for |
|---|---|---|---|---|
| Git | Yes | `brew install git` | `winget install Git.Git` | Clone / PR |
| Azure CLI (`az`) | Yes | `brew install azure-cli` | `winget install Microsoft.AzureCLI` | Tokens, Key Vault, Fabric REST |
| Fabric CLI (`fab`) | Yes | `pip install ms-fabric-cli` | `py -3 -m pip install ms-fabric-cli` | Live Fabric items |
| Python 3.11+ | Yes | `brew install python@3.12` | `winget install Python.Python.3.12` | `automation/`, dbt |
| ODBC Driver 18 | Yes for warehouse scripts | `brew install --cask microsoft-odbc-driver-18-for-sql-server` | `winget install --id Microsoft.msodbcsql.18 -e` | `pyodbc`, dbt-fabric |
| `pyodbc` | Yes for warehouse scripts | `pip install pyodbc` | same | SQL to Fabric warehouses |
| `dbt` + `dbt-fabric` | Yes for analytics | `pip install -r dbt/requirements.txt` | same | Analytics views |
| PowerShell 7 (`pwsh`) | Recommended | `brew install powershell` | `winget install Microsoft.PowerShell` | Cross-platform scripts |
| Cursor or VS Code | Recommended | download | download | Agent + rules |
| GitHub CLI (`gh`) | Optional | `brew install gh` | `winget install GitHub.cli` | Only if using GitHub PRs |
| Node.js | Optional | `brew install node` | `winget install OpenJS.NodeJS.LTS` | Rare local UI tooling |
| Playwright | Optional | `pip install playwright` + `playwright install chromium` | same | Local scrape heal |
| Azure Functions Core Tools | Optional | brew / npm | winget | Paginated export API local |
| Azure DevOps CLI | Optional | `az extension add --name azure-devops` | same | ADO boards / pipelines |

Package name for Fabric CLI can change; if `ms-fabric-cli` fails, use current Microsoft Fabric CLI install docs and ensure `fab` is on `PATH`.

---

## 11. What not to do

- Do not commit `.venv/`, secrets, `.env`, or Key Vault values.
- Do not enable Fabric schedules unless someone explicitly asks.
- Do not write to Operations / Finance / GBP-Enterprise / production as a default.
- Do not invent `dim_` / `fact_` / `EDW_*` / `pl_` names for new Foundation Development work.
- Do not open a parent folder as the workspace; open **Foundation** itself.

---

## 12. Minimal checklist

- [ ] Entra + ADO + Fabric access granted  
- [ ] Git, az, Python 3.11+, ODBC 18, fab installed  
- [ ] Repo cloned; IDE opened at Foundation root  
- [ ] `.venv` created; `dbt/requirements.txt` + `pyodbc` installed  
- [ ] `~/.dbt/profiles.yml` from `dbt/profiles.yml.example`  
- [ ] `az login` + `fab auth login` succeed  
- [ ] `fab ls "Foundation Development.Workspace"` returns items  
- [ ] Agent smoke questions pass  
- [ ] Optional: Playwright, MCP, Key Vault role  

---

## Related docs

| Doc | Role |
|---|---|
| [`agent-setup.md`](agent-setup.md) | Replicate AI agent rules across IDEs |
| [`ado-git.md`](ado-git.md) | ADO remote and auth |
| [`identity.md`](identity.md) | Workspace Identity / Key Vault |
| [`analytics-setup.md`](analytics-setup.md) | dbt + lakehouse refresh |
| [`web-scrape-setup.md`](web-scrape-setup.md) | Scrape registry and pipelines |
| [`../../AGENTS.md`](../../AGENTS.md) | Canonical agent instructions |
| [`../../README.md`](../../README.md) | Repo entry + short smoke |
