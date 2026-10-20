#!/usr/bin/env bash
# Install this repo as a Cursor local plugin (copy, not an out-of-tree symlink).
# Cursor skips symlinks that point outside ~/.cursor/plugins/local.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${CURSOR_LOCAL_PLUGIN_DIR:-$HOME/.cursor/plugins/local/data-warrior-forge}"

mkdir -p "$(dirname "$DEST")"
rm -rf "$DEST"
mkdir -p "$DEST"

# Copy the plugin surface + Forge package. Exclude build junk and git.
rsync -a \
  --delete \
  --exclude '.git/' \
  --exclude '.venv/' \
  --exclude '__pycache__/' \
  --exclude '*.egg-info/' \
  --exclude '.pytest_cache/' \
  --exclude '.ruff_cache/' \
  --exclude '.mypy_cache/' \
  --exclude 'demos/local_orders/factory_jobs/' \
  --exclude 'forge-line/jobs/' \
  --exclude '.cursor/.welcome_sessions/' \
  "$ROOT/" "$DEST/"

if [[ ! -f "$DEST/.cursor-plugin/plugin.json" ]]; then
  echo "ERROR: missing .cursor-plugin/plugin.json in $DEST" >&2
  exit 1
fi

echo "INSTALLED Cursor local plugin -> $DEST"
echo "Next: Developer: Reload Window, then Customize → confirm data-warrior-forge"
echo "Then open a work project and start a new Agent chat (welcome + level)."
