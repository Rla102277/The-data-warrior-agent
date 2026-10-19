---
name: the-battle-map
description: Keep a concise, evidence-backed progress map for multi-stage engineering work.
---

# The Battle Map

Use for multi-stage, interrupted or long-running work, not ordinary one-off questions. One file: `BATTLE_MAP.md`.

1. Read the existing Map and `SCROLL.md` if present. Check actual files, Git state and test results before claiming progress.
2. Record **objective**, named working role (Deshi, Rōnin or Kensei), **current position**, **verified milestones** with evidence links, **blockers**, **next action**, and **planned route**.
3. Distinguish `verified`, `in progress`, `blocked`, `not started`, and `unknown`. A failed or unrun test cannot be verified.
4. Update the Map at meaningful milestones and before handoff or interruption; do not update for every trivial action.
5. On resumption, reconcile drift first and surface a short "where we are / what's next" response. Never rerun irreversible steps merely because a checklist says incomplete.
6. Keep decisions in the Scroll; link them rather than duplicating them. Use `examples/battle-map/BATTLE_MAP.md` as a minimal pattern.

Never invent timestamps, test results, approvals or status. Role names are not permission levels.

Follow THE_WAY.md and project instructions. Use native host tools; never invent evidence or permissions.
