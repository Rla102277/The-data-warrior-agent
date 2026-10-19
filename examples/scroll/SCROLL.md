# Scroll — Example: Orders ingestion

> Illustrative example only. Not a real project state.

## Goal
Ingest orders incrementally with safe replay and predictable updates.

## Verified facts
- None yet. Confirm source schemas and change-feed capabilities from the actual repository.

## Decisions
| ID | Decision | Rationale | Status | Evidence |
|---|---|---|---|---|
| D-001 | Use an immutable event identifier if the source provides one | Enables replay deduplication | Proposed | Source contract not yet inspected |

## Assumptions
- Source exposes stable event identifiers. **Unverified.**

## Contradictions
- None identified.

## Acceptance tests
- Replaying the same batch does not duplicate records.
- An update supersedes the prior state without losing history if history is required.
- Late events follow an explicitly defined watermark policy.

## Next challenge
What uniquely identifies an order change across retries?

## Last checkpoint
Example only; no work performed.
