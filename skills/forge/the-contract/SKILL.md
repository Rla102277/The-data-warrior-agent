---
name: the-contract
description: Use when defining or changing producer-consumer schemas, data quality guarantees, ownership, compatibility and data contract tests.
---

# The Contract

## Contract decisions
- Name producer, consumers, dataset purpose, ownership, classification, refresh/freshness SLO and escalation path.
- Specify business and technical keys, uniqueness scope, field type, nullability, semantic meaning, timezone, units, allowed values and sensitive data handling.
- Define change compatibility: additive nullable fields, required-field introduction, renames, type narrowing, key changes and consumer migration windows. Don't call a schema change safe without checking consumers.
- Express operational guarantees: update cadence, event ordering, late arrival, deduplication, delete semantics, historical corrections and retention.
- Specify validation location (source, landing, transform, serving), severity, quarantine strategy and remediation ownership.
- Provide valid, invalid and backward-compatibility fixtures. Execute checks when tooling is available.
- Choose a contract representation the tools already on the terrain can enforce. Do not invent a vendor-native contract system.
## Failure modes
A contract that checks only field names misses semantics. Nullable does not mean unknown is acceptable. Row counts cannot establish referential integrity. An upstream delete policy must not be guessed.
## Deliverable
Minimal machine-readable schema or SQL checks plus human-readable ownership, guarantees, migration plan and test evidence. Clearly mark unexecuted validations.

Follow project instructions and the installed THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
