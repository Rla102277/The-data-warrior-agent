---
name: to-steps
description: Use when a forge spec exists and must be broken into ordered steps each small enough to build and fail a test.
disable-model-invocation: true
---

# To Steps

Read `spec.md` and the Scroll. Call `the-battle-map` and `chart-the-path`.

Write ordered steps into `BATTLE_MAP.md` and `forge-line/jobs/<job-id>/steps.md`. Each step must name:

- Input and output.
- Proof that will go red before green.
- Stop condition (when this step is done).
- Dependencies and rollback note.

One step is the current build target. Later steps stay unbuilt. Analyst jobs may end at a trusted answer. Engineer jobs continue through contract, load, transform, and reconciliation as the action requires.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
