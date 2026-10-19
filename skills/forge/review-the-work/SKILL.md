---
name: review-the-work
description: Use when a forge build needs independent security, naming, and data-quality review files before human approval.
---

# Review The Work

Produce three review files for the current job round. The builder does not approve their own job.

Each file must start with `VERDICT: PASS` or `VERDICT: CHANGES`, then evidence-backed findings:

- **security** (Guardian perspective): secrets, access, PII, policy gates, destructive actions.
- **naming** (Architect perspective): layers (raw/stage/control/transform/analytics), keys, clarity.
- **data-quality** (Examiner perspective): grain, duplicates, deletes, null keys, reconciliation, contract fit.

Strategist, Engineer, and Sensei are additional Council perspectives. Use them only when they change a verdict. They are not extra review files and not separate agents. Do not claim six autonomous reviewers. Do not claim multi-agent review unless distinct reviewers actually ran.

Also record each review with `forge job review` so the verdict, reviewer, build id, and evidence ids are machine-checkable. Markdown that says `VERDICT: PASS` without that record does not count. Three files from one reviewer are three perspectives, not three independent reviewers. Set `--provenance independent` only when a different reviewer actually ran that review. A review of an earlier build is stale after rework.

Follow project instructions and THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
