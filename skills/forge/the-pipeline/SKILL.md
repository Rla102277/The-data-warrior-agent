---
name: the-pipeline
description: Use when building or changing ingestion, batch/stream processing, CDC, incremental loads, Delta MERGE, SCD history or lakehouse pipelines.
---

# The Pipeline

## Decide before implementing
1. Identify source and target, ownership, business keys, event identity, ordering, latency, delete semantics, expected volume, SLA and replay horizon. Inspect real schema and available change feeds.
2. **CDC vs watermark:** Prefer a reliable source log/change feed when deletes and intermediate updates matter. Timestamp watermarking is only safe with trustworthy monotonic change timestamps, overlap/reconciliation and tie-breaking keys; `MAX(updated_at)` alone can miss equal-timestamp, delayed and backdated rows. Define initial load, backfill and cursor recovery.
3. **Idempotency:** Assume at-least-once delivery. Deduplicate by stable source event ID or deterministic key plus version. Define deterministic winner for multiple source rows per target key before MERGE. A MERGE statement by itself is not proof of idempotency; retries, partial commits and nondeterministic transformations can change results.
4. **Deletes:** Distinguish source tombstone, soft delete, hard delete and absence from a snapshot. Do not infer deletes from missing incremental rows. Define retention, audit and propagation to consumers.
5. **History:** Current-state upsert, periodic snapshot, SCD Type 2 and event history solve different questions. SCD2 needs effective intervals, one current row per natural key, late corrections, no overlapping validity and reproducible surrogate keys. Data Vault hubs represent stable business keys, links relationships, satellites descriptive/history changes; don't use Data Vault by reflex.
6. **Watermarks and recovery:** Track cursor/checkpoint only after durable target success. Handle identical timestamps, out-of-order events, source retention limits and replay window. Design reprocessing/backfill without double counting.
7. **Schema evolution:** Classify additive, breaking, type narrowing, nullability and key changes; quarantine unknown records and negotiate contracts. Don't silently cast corrupt values to null.
8. **Data quality:** Test uniqueness, referential integrity, freshness, completeness, reconciliation, source-target counts/checksums and contract conformance. Define alert thresholds and ownership.
9. **Observability:** Capture run ID, source cursor, records read/inserted/updated/deleted/rejected, duration, retry count and lineage without leaking secrets.
10. **Named tools only:** Use the storage, orchestrator, and runtime recorded on the ground. Do not assume a vendor. Confirm that engine's transactional boundaries and MERGE semantics before writing them. A Spark API and a SQL warehouse are different tools; use the one the terrain named.
## Prove it
Test duplicate delivery, two updates with same timestamp, out-of-order events, source delete, empty batch, failed target write before checkpoint, backfill and schema change. Use a fixture with expected rows and compare actual outputs. State which tests were run and which remain proposed.
## Anti-patterns
Blind `MAX(updated_at)`; nondeterministic dedupe; checkpoint-before-commit; hard-delete by incremental absence; SCD2 without interval invariants; treating row-count equality as full reconciliation; fabricating source CDC support.

Follow project instructions and the installed THE_WAY.md. Use native host tools, respect permissions, and distinguish observed evidence from assumptions.
