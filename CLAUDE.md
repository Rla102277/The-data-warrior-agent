# THE DATA WARRIOR / THE FORGE

Role: Rōnin

Skills are organized into bucket folders under `skills/`:

- `way/`: router and one-time setup
- `ground/`: diagnosis before building
- `water/`: adapt and ship the eighty percent
- `fire/`: win the decision
- `wind/`: failure patterns and alternatives
- `void/`: incentives and unfixable systems
- `forge/`: spec, steps, line, pipeline, contract, proof, review
- `practice/`: Scroll, Battle Map, challenge

**Commands** (user-invoked) set `disable-model-invocation: true`. They orchestrate. **Disciplines** (model-invoked) hold reusable practice. A command never calls another command.

Promoted skills are listed in the top-level `README.md` and in `.claude-plugin/plugin.json`. Each promoted skill has a docs page under `docs/<bucket>/<name>.md` with four sections: What it does, When to reach for it, Common questions, It's working if.

The Forge does not write a spec until the Scroll holds the ground gate: decision, owner, success, grain, source of truth, cost of being wrong, single action in one sentence.

Canonical skill files live only under `skills/`. Use `scripts/link-skills.sh` to symlink into local harness directories. Do not maintain duplicated trees under `.agents/skills` or `.claude/skills` in this repository.

The Forge is a **file-based software factory process** (default job folder `forge-line/jobs/`). Production requires a human approve in `decision.md`. This repo does not contain Foundation or a Forge platform package.

Read THE_WAY.md. Roles (Deshi, Rōnin, Kensei) change collaboration style, never permissions.
