---
name: to-spec
description: Use when one agreed action exists on the Scroll and must become a forge job specification with proof criteria.
disable-model-invocation: true
---

# To Spec

Refuse to run if the Scroll is missing the ground gate fields from `/know-the-ground`. Call `the-scroll` to read them.

If a `PLAN.md` (or job `plan.md`) exists from `/to-plan`, read it and keep the spec aligned to the aim, locked defaults, and current phase. Do not re-litigate the whole campaign inside the spec.

Write `forge-line/jobs/<job-id>/spec.md` containing:

- Single action (verbatim from the Scroll).
- Decision owner and success definition.
- Grain, source of truth, target, and contract notes.
- Input, output, and ownership.
- Proof criteria: replay, duplicates, deletes, reconciliation as applicable.
- Layers when relevant: raw / stage / control / transform / analytics.
- Autonomy level (default 2) and explicit production authorization requirement.

Create `job.json` stub with stage `SPECIFICATION` when the `forge` CLI is available (`forge job create`). Otherwise write the files by hand and say so. Do not build.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
