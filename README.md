# THE DATA WARRIOR

**Small skills. Deep judgment. No ceremony.**

A native-first collection of focused engineering skills inspired by the creator's eight Musashi-derived disciplines. Works through Cursor, Codex and Claude Code's existing agent model and tools. No Python web app, mandatory runtime or separate model API key.

## Start in Cursor
Open this repository in Cursor Agent and invoke any skill directly:
- `/the-challenge` — rigorous one-question-at-a-time interrogation, no documents.
- `/the-scroll` — **The Challenge with living context**: one question at a time, an evolving `SCROLL.md`, decisions, contradictions and requirements.
- `/the-battle-map` — lightweight progress and recovery map for substantial work.
- `/survey-the-ground` — inspect what actually exists.
- `/study-the-wind` — compare approaches.
- `/council-of-masters` — critical specialist review.
- `/chart-the-path` — practical plan.
- `/draw-the-blade` — build and verify.
- `/forge-the-pipeline` — data pipelines.
- `/forge-a-contract` — data contracts.
- `/test-the-steel` — execute tests.
- `/sharpen-the-blade` — measured improvement.
- `/lessons-of-battle` — capture learning.
- `/the-campaign` — **optional** coordination of a large initiative.

The reusable `the-interrogation` method powers both The Challenge and The Scroll.

## Roles
**Deshi** — guided apprentice. **Rōnin** — independent practitioner within agreed scope. **Kensei** — trusted master with explicitly delegated scope. These are named roles, not numbered tiers. None bypasses Cursor, GitHub or cloud permissions. Read [The Way](THE_WAY.md).

## The Scroll and The Battle Map
The Scroll is a living, challenging conversation, not a document factory. It creates `SCROLL.md` when decisions become worth retaining. The Battle Map is a compact `BATTLE_MAP.md` for multi-stage work and recovery, not a mandatory form.

## Design
Canonical skills live in `skills/`. The host-native mirrors in `.agents/skills/`, `.claude/skills/` and `.cursor/commands/` are maintained for compatibility. The command files are tiny pointers. No mandatory mission scaffolding, formal handoffs or universal gate checks.

## Install
Use the optional installer: `python3 scripts/install.py /path/to/your/project`. Or copy the specific skill folders you want into the target host's skills directory. Do not overwrite existing project instructions. The installer is optional; Python is not used to run the skills.

## Verify
```bash
python3 scripts/verify.py
python3 -m unittest discover -s tests -v
```
These are structural tests, not live model evaluations. Use [Live Testing](docs/LIVE-TESTING.md) to assess behavior.

THE DATA WARRIOR is independent of Foundation; Azure and Microsoft Fabric are optional target environments.
