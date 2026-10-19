---
name: review-the-work
description: Use when a forge build needs independent security, naming, and data-quality review files before human approval.
---

# Review The Work

Produce three review files for the current job round. The builder does not approve their own job.

Each file must start with `VERDICT: PASS` or `VERDICT: CHANGES`, then evidence-backed findings:

- **security**: secrets, access, PII, policy gates, destructive actions.
- **naming**: layers (raw/stage/control/transform/analytics), keys, clarity.
- **data-quality**: grain, duplicates, deletes, null keys, reconciliation, contract fit.

Use lenses from architecture, pipeline engineering, governance, operations, cost, and consumer impact only when they change the verdict. Do not claim multi-agent review unless distinct agents were used.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
