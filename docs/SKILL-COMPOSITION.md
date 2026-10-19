# Skill design

Fourteen canonical `skills/<name>/SKILL.md` files are the only manually edited definitions. `python3 scripts/sync.py` generates compatible `.agents/skills`, `.claude/skills` and thin `.cursor/commands` files; `--check` detects drift. Never edit generated mirrors.

The Challenge and Scroll independently include the one-question method; no internal skill dependency. The Scroll is the living intellectual record; Battle Map is optional execution state. Skills can be invoked directly without a mandatory coordinator.

Installer defaults to Cursor, with `--host claude`, `--host codex`, or `--host all`. It installs only selected skills and chosen host adapters, `THE_WAY.md`, and missing project role configuration. It preserves existing project instructions.

Use skill descriptions that begin "Use when..." and name user intents, technology and engineering problems. Keep interaction skills short; data-engineering skills should encode failure cases and tradeoffs.
