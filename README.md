# THE DATA WARRIOR

**Small skills. Deep judgment. No ceremony.**

Native agent skills for Cursor, Codex and Claude Code, inspired by eight Musashi-derived engineering disciplines. No custom model service, web app or required runtime.

## Invoke a skill
- `/the-challenge` — one-question-at-a-time adversarial thinking, no files.
- `/the-scroll` — **The Challenge with persistent context**: one question at a time, evolving `SCROLL.md`, evidence, decisions and contradictions.
- `/the-battle-map` — optional, concise `BATTLE_MAP.md` for milestones and recovery.
- `/survey-the-ground` — inspect a codebase.
- `/study-the-wind` — compare alternatives.
- `/council-of-masters` — specialist review.
- `/chart-the-path` — plan.
- `/draw-the-blade` — implement.
- `/forge-the-pipeline` — data pipelines.
- `/forge-a-contract` — data contracts.
- `/test-the-steel` — verify with real tests.
- `/sharpen-the-blade` — measured improvements.
- `/lessons-of-battle` — lessons learned.
- `/the-campaign` — **optional** initiative coordination.

The internal `the-interrogation` method is shared by The Challenge and The Scroll.

## Roles
**Deshi** — guided apprentice. **Rōnin** — independent practitioner. **Kensei** — trusted master with delegated scope. These are collaboration styles, not permission levels. See [The Way](THE_WAY.md) and [role behavior](docs/ROLE-BEHAVIOR.md).

## Install selected skills
```bash
python3 scripts/install.py /path/to/project the-scroll the-battle-map
```
The Scroll installer includes its shared interrogation dependency. You can also copy skills manually; Python is optional tooling, not an agent runtime.

## Verify
```bash
python3 scripts/verify.py
python3 -m unittest discover -s tests -v
```
GitHub Actions runs structural checks; **live agent behavior is not proven by CI**. See [live tests](docs/LIVE-TESTING.md).

Canonical skills are under `skills/`; mirrored `.agents/skills/`, `.claude/skills/` and `.cursor/commands/` support host discovery. Read [composition](docs/SKILL-COMPOSITION.md). See [Scroll example](examples/scroll/SCROLL.md) and [Battle Map example](examples/battle-map/BATTLE_MAP.md).

Azure and Fabric are optional targets. THE DATA WARRIOR is independent of Foundation.
