---
name: sharpen-the-blade
description: Use when refactoring or tuning a slow, expensive, fragile or hard-to-maintain data pipeline with measured before/after results.
---

# Sharpen The Blade

Establish baseline of latency, capacity consumption, scan/shuffle volume, failures and data correctness. Locate bottleneck via query plan, partitions, skew, file sizes, joins or orchestration overhead. Change one meaningful variable and retest invariants. For Delta consider small-file pressure, pruning, compaction and concurrent writes only where supported. For Fabric verify actual capacity and workload metrics. Report tradeoffs and rollback; don't claim speedup without measurements.

Follow project instructions and the installed THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
