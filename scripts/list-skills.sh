#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
find "$ROOT/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | sort | while read -r skill; do
  bucket="$(basename "$(dirname "$(dirname "$skill")")")"
  name="$(basename "$(dirname "$skill")")"
  echo "$bucket/$name"
done
