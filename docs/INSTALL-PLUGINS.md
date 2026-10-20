# Install — Cursor plugin and Claude plugin

**Skills and the Forge ship as one package** (`data-warrior-forge`).

Be honest about what works **today** vs what is still waiting on a marketplace listing.

| Path | Works today? | Who it is for |
| --- | --- | --- |
| Cursor **local plugin copy** (`scripts/install-cursor-local.sh`) | **Yes** | Anyone on Cursor |
| Cursor **project copy** (`scripts/install.py`) | **Yes** | Sandbox folder without plugins |
| Claude Code **marketplace add** this GitHub repo | **Yes** (Claude Code CLI) | Anyone with Claude Code |
| Claude Code `--plugin-dir` | **Yes** | Local checkout |
| Cursor **official Marketplace** listing | **No** — not submitted/listed yet | Later |
| Cursor “add GitHub marketplace” like Claude | **Only Teams/Enterprise** team marketplaces — not a personal one-click for everyone | Orgs on Teams+ |

---

## Cursor — what to do today

### 1. Local plugin (recommended)

From a clone of this repo:

```bash
cd /path/to/the-data-warrior-agent
./scripts/install-cursor-local.sh
```

That **copies** the repo into `~/.cursor/plugins/local/data-warrior-forge/`.

Do **not** `ln -s` this repo into `plugins/local`. Cursor **skips** symlinks that point outside that folder.

Then:

1. **Developer: Reload Window** (or restart Cursor).
2. Open **Customize** and confirm **data-warrior-forge** (skills / rules / commands).
3. Open your **work** project (not only this repo).
4. Start a **new Agent chat**. Expect welcome → level → setup menus → ground.

To update after we push changes: pull this repo, run `./scripts/install-cursor-local.sh` again, reload.

### 2. Project folder copy (sandbox)

If you want skills copied into one project instead of a user plugin:

```bash
mkdir -p ~/Projects/my-warrior-trial
python3 scripts/install.py ~/Projects/my-warrior-trial --host cursor --overwrite
```

Open that folder in Cursor → new Agent chat.

### 3. Not available yet

- Official [Cursor Marketplace](https://cursor.com/marketplace) listing — submit when ready: [publish](https://cursor.com/marketplace/publish).
- Personal “add any GitHub repo as marketplace” — that flow is for **Team marketplaces** (Teams/Enterprise), not a substitute for (1) above.

---

## Claude Code — what to do today

### 1. Marketplace from this GitHub repo

```bash
claude plugin marketplace add https://github.com/Rla102277/The-data-warrior-agent
claude plugin install data-warrior-forge@data-warrior
```

Marketplace name in this repo: `data-warrior` (see `.claude-plugin/marketplace.json`).  
Plugin name: `data-warrior-forge`.

Or in a session: `/plugin` → Marketplaces → add the GitHub URL → install **data-warrior-forge**.

### 2. Load a local checkout

```bash
claude --plugin-dir /path/to/the-data-warrior-agent
```

### 3. After Claude install

Work in your project folder. Run `/setup-the-forge` if welcome does not start. Then `/know-the-ground`.

Optional Forge CLI (same package, separate Python install):

```bash
cd /path/to/the-data-warrior-agent
python3 -m venv .venv && source .venv/bin/activate
pip install -e '.[local]'
forge doctor
```

---

## Maintainers

```bash
python3 scripts/sync-plugin-surface.py
python3 scripts/verify.py
./scripts/install-cursor-local.sh   # refresh your own Cursor local install
```
