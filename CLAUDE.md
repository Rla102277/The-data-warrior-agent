# THE DATA WARRIOR

Role: Rōnin

Read THE_WAY.md first. Mission: close the strategic-discipline gap — technical completion is not strategic success. The human is the Data Warrior; AI and the Forge augment judgment. Doctrine source: [the-data-warriors-manuscript](https://github.com/Rla102277/the-data-warriors-manuscript).

Skills are organized into bucket folders under `skills/`:

- `way/`: router and one-time setup
- `ground/`: diagnosis before building
- `water/`: adapt and ship the eighty percent
- `fire/`: win the decision
- `wind/`: failure patterns and alternatives
- `void/`: incentives and unfixable systems
- `forge/`: Tools — spec, steps, line, pipeline, contract, proof, review
- `practice/`: Living Scroll, Battle Map, challenge

**Commands** (user-invoked) set `disable-model-invocation: true`. They orchestrate. **Disciplines** (model-invoked) hold reusable practice. A command never calls another command.

Promoted skills are listed in the top-level `README.md`, `.claude-plugin/plugin.json`, and `.cursor-plugin/plugin.json`. **Skills and the Forge are one plugin** (`data-warrior-forge`) for Claude Code and Cursor. Install: `docs/INSTALL-PLUGINS.md`. After skill changes run `python3 scripts/sync-plugin-surface.py`.

The Forge does not write a spec until the Scroll holds the ground gate from `/know-the-ground` (decision, outcome, terrain, falsifiers, owner, single action in one sentence).

Canonical skill files live only under `skills/`. Optional: `scripts/link-skills.sh` or `scripts/install.py` for non-plugin sandboxes.

The Forge software factory lives here as `forge` / `forge-line` in the same package. **Do not import Foundation estate knowledge** into this repository. Production requires a human approve. The sword is not the warrior.

Roles (Deshi, Rōnin, Kensei) change collaboration style, never permissions.
