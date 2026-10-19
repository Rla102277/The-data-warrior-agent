# Azure DevOps git (Foundation)

**Updated:** 2026-08-26  
**Status:** ADO project and repo exist. Local/portable onboarding connected
to this remote. Fabric workspace git on Foundation Development remains
`NotConnected` (follow-up; `fabric/` stays gitignored in this local tree).

## Remote (confirmed)

| Setting | Value |
|---|---|
| Org | `https://dev.azure.com/grbk` |
| Project | **Foundation** (`f59add8d-e794-424a-9e59-402817579d9d`) |
| Repo | **Foundation** (`d52fcc54-e4d7-496f-834b-2a278c05088c`) |
| Clone URL | `https://dev.azure.com/grbk/Foundation/_git/Foundation` |
| Branch | `main` |
| Web | https://dev.azure.com/grbk/Foundation/_git/Foundation |

Older docs referred to project `Fabric` / repo `foundation`. That create path
is obsolete. Use **Foundation / Foundation**.

## Local connect

```bash
cd ~/Documents/Projects/Foundation
git remote add origin https://dev.azure.com/grbk/Foundation/_git/Foundation
# or: git remote set-url origin https://dev.azure.com/grbk/Foundation/_git/Foundation
git fetch origin
git push -u origin main   # after fetch/merge; no force unless approved
```

Auth: Azure DevOps HTTPS credential or `az` + Git Credential Manager.

Helper script (defaults updated 2026-08-26):

```bash
bash automation/connect_foundation_ado_git.sh
```

## What to push

At minimum for agent/portability and platform code:

- `AGENTS.md`, `README.md`, fork pointer files (`.github/`, `.windsurfrules`, `.continuerules`)
- `.cursor/rules/`
- `knowledge/`
- `dbt/`
- `automation/` (sql, scripts)

Do not commit secrets, `snapshots/`, or local `fabric/` (gitignored).

## Fabric workspace git (later)

When wiring Foundation Development to ADO for item definitions:

| Setting | Value |
|---|---|
| Workspace | Foundation Development (`40502864-6ece-49b5-807f-6f7c11d1b3e1`) |
| Directory in repo | `fabric` |
| Foundation twin git | Leave **NotConnected**. Prod changes go through the deployment pipeline. |

1. `POST /v1/workspaces/{FD}/gitConnect` (or `bash automation/connect_foundation_ado_git.sh`)
2. Initialize PreferWorkspace from Fabric UI or API
3. Branch policy on `main`: PR + one reviewer
4. Optional ADO pipeline for `dbt build` via `automation/run_dbt_analytics.sh`

## CI stub (ADO YAML)

Place in repo as `azure-pipelines-dbt.yml` when ready:

```yaml
trigger:
  paths:
    include:
      - dbt/**
pool:
  vmImage: ubuntu-latest
steps:
  - script: |
      pip install dbt-fabric
      ./automation/run_dbt_analytics.sh build
    displayName: dbt build
```

## Related

- Agent setup: [`agent-setup.md`](agent-setup.md)
- Access / SoD RBAC: [`identity.md`](identity.md)
- SOX: Change management (ITGC-CM-01)
