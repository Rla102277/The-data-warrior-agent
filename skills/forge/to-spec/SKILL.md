---
name: to-spec
description: Use when one agreed action exists on the Scroll and must become a forge job specification with proof criteria.
disable-model-invocation: true
---

# To Spec

Refuse to run if the Scroll is missing the ground gate fields from `/know-the-ground`. Call `the-scroll` to read them.

Write `forge-line/jobs/<job-id>/spec.md` containing:

- Single action (verbatim from the Scroll).
- Decision owner and success definition.
- Grain, source of truth, target, and contract notes.
- Input, output, and ownership.
- Proof criteria: replay, duplicates, deletes, reconciliation as applicable.
- Layers when relevant: raw / stage / control / transform / analytics.
- Autonomy note (build and test in isolation by default) and explicit production authorization requirement.

Also write a minimal `job.json` with stage `SPECIFICATION`. Create directories as needed. Do not build.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
