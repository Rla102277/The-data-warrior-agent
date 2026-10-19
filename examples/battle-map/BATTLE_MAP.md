# Battle Map — Example: Orders ingestion

> Illustrative example; no implementation or tests have been run.

**Objective:** Reliable incremental orders ingestion
**Terrain:** Source semantics unknown; no production workspace is in scope
**Dependencies:** Source contract, key, and delete semantics
**Risks:** Building incrementality before replay and deletes are known
**Decisions:** None yet — see the Scroll
**Role:** Rōnin (example, not actual authorization)
**Position:** Discovery — source semantics unknown
**Scroll:** [../scroll/SCROLL.md](../scroll/SCROLL.md)

## Verified milestones
- None.

## Route
- [ ] Inspect source schema and change semantics
- [ ] Confirm key and replay contract
- [ ] Implement incremental ingestion
- [ ] Execute duplicate, late-data and replay tests

## Blockers
- Unknown event identifier and update/delete semantics.

## Next action
Inspect the actual source contract; challenge missing assumptions.

## Proof
No command has been run. No artifact path. Do not mark any milestone complete.
