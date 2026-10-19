# Fabric engineering decision guide

This is optional guidance for projects actually using Microsoft Fabric. Inspect the target project's existing architecture, identity, capacity, deployment setup and committed decisions before prescribing components. Do not assume Foundation's structure applies elsewhere.

## Lakehouse vs Warehouse
- Lakehouse/Delta is useful for Spark-native transformations, files, medallion-like processing and open table semantics. Confirm table format and supported APIs.
- Warehouse supports T-SQL-oriented relational serving and governance patterns. Verify feature and transaction support for the actual Fabric release before selecting MERGE/DDL.
- Avoid cross-engine assumptions: Spark Delta writes, Warehouse SQL and SQL analytics endpoints do not share identical capabilities.

## Ingestion and orchestration
- Identify source CDC/change tracking, API pagination and rate limits, delete events, late arrivals, checkpoint retention and backfill. Prefer source log semantics when reliable.
- Use Fabric Data Factory pipelines, Dataflow Gen2, notebooks or event/stream processing only when they fit actual workloads and team operations. Separate orchestration from transformation where useful.
- Commit checkpoint only after durable target success. For MERGE, deduplicate incoming events by key/version deterministically.

## Governance and deployment
- Verify workspace identities, connections, secrets, environment bindings, deployment pipelines, capacity, OneLake access and least-privilege roles.
- Treat development and production as distinct security and validation boundaries. Never infer deployment authority from the agent role.
- Capture lineage, run telemetry, quality failures and recovery procedures.

## Performance and cost
- Measure capacity consumption, query latency, Spark startup, file layout, partitions, skew, concurrency and pipeline retries before tuning.
- Validate proposed optimization with real metrics; don't recommend compaction, partitioning or caching without workload evidence.

## Required tests
Duplicate delivery, same-timestamp update, tombstone delete, partial-failure checkpoint, schema drift, reconciliation, history correctness and access-control failure.
