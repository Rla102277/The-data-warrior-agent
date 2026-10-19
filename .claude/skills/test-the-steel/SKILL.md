---
name: test-the-steel
description: Use when validating a code or data pipeline change, investigating failed tests, or proving correctness under replay, deletes and schema drift.
---

# Test The Steel

Build tests from invariants rather than string presence. For ingestion cover initial load, duplicate events, same-timestamp changes, late arrivals, deletes, null keys, schema drift, checkpoint failure, replay and reconciliation. For SCD2 assert nonoverlapping intervals and exactly one current row per key. For contracts include valid/invalid records and compatibility cases. Run real commands when permitted; capture command, exit code, output and limitations. A skipped test is unknown, not passed.

Follow project instructions and the installed THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
