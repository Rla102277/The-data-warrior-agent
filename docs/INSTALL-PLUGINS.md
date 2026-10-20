# Install — Cursor plugin and Claude plugin

**Skills and the Forge ship as one package.** Do not install “skills only” without the Forge doctrine and factory companions in this repo.

## Cursor (first-class)

### A. Local / team marketplace (GitHub repo)

1. In Cursor: **Customize → Plugins / Marketplaces** (wording varies by version).
2. Add marketplace from GitHub: `Rla102277/The-data-warrior-agent`  
   (repo root has `.cursor-plugin/marketplace.json`).
3. Install **`data-warrior-forge`** at **user** or **project** scope.
4. Open a project → **new Agent chat**. Expect welcome, level menu, then setup/ground.

### B. Develop / test from this checkout

```bash
mkdir -p ~/.cursor/plugins/local
ln -sfn "$(pwd)" ~/.cursor/plugins/local/data-warrior-forge
```

Reload Cursor. The plugin name is `data-warrior-forge`.

### C. Official Cursor Marketplace

Submit this repository for review when ready ([Cursor plugins](https://cursor.com/docs/plugins)). Until listed, use A or B.

## Claude Code (first-class)

### A. Marketplace from this repo

```bash
claude plugin marketplace add Rla102277/The-data-warrior-agent
claude plugin install data-warrior-forge@data-warrior
```

Or in a session: `/plugin` → Marketplaces → add this GitHub repo → install **data-warrior-forge**.

### B. Load from a local checkout (no marketplace)

```bash
claude --plugin-dir /path/to/the-data-warrior-agent
```

### C. After install

Start a session in your work project. Run `/setup-the-forge` (or rely on welcome guidance). Then `/know-the-ground`. The Forge CLI remains optional for job persistence:

```bash
cd /path/to/the-data-warrior-agent
python3 -m venv .venv && source .venv/bin/activate
pip install -e '.[local]'
forge doctor
```

## Keep the surface in sync (maintainers)

After adding or renaming skills:

```bash
python3 scripts/sync-plugin-surface.py
python3 scripts/verify.py
```

That regenerates `commands/`, `hooks/`, `rules/`, `.cursor-plugin/plugin.json`, and `.claude-plugin/plugin.json` from canonical `skills/`.

## Project copy install (still supported)

For a sandbox folder without plugin hosts:

```bash
mkdir -p ~/Projects/my-warrior-trial
python3 scripts/install.py ~/Projects/my-warrior-trial --host cursor --overwrite
```

Prefer plugins for day-to-day use so updates come through the marketplace.
