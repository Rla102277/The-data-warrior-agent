#!/usr/bin/env bash
# Symlink promoted skills into local harness directories (Matt-style).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$HOME/.agents/skills" "$HOME/.claude/skills"
while IFS= read -r -d '' skill; do
  name="$(basename "$(dirname "$skill")")"
  for dest in "$HOME/.agents/skills/$name" "$HOME/.claude/skills/$name"; do
    ln -sfn "$(dirname "$skill")" "$dest"
    echo "LINKED $dest -> $(dirname "$skill")"
  done
done < <(find "$ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md -print0)
