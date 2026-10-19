# BuilderMetrix landing in Foundation

**Created:** 2026-08-20  
**Decision:** D18  
**Status:** Raw landing zone only. No connection, no load, no schedule.
Foundation twin not provisioned yet.

Vendor product is **BuilderMetrix** (Constellation HomeBuilder Systems), the
same ERP vendor as NEWSTAR. Green Brick already lands NEWSTAR through
`HBLive` / `SPLive` mirrors. BuilderMetrix is an analytics / benchmarking
product on top of that ERP, not a replacement for the books of record.

## Where it lives

| Field | Value |
|---|---|
| Workspace | Foundation Development only |
| Folder | `raw` |
| Lakehouse | `lake_house_buildermetrix` `9f3fe55b-b89b-4213-af3c-7aaebc0561fe` |
| Pattern | Same as Zonda: vendor product lands in `raw`, then dbt / presentation later if we consume it |

Do not bind BuilderMetrix into `lake_house_analytics` or Finance reports until
there is a named consumption model. Do not overwrite `HBLive` / `SPLive`.

## Intended path (once the vendor says how they deliver)

```
Constellation BuilderMetrix
  -> Foundation Development raw / lake_house_buildermetrix
  -> (later) warehouse_stage.transform / analytics dbt if we certify off it
  -> (later) lake_house_analytics presentation
```

Constellation documents a SQL data extension that can push aggregated,
anonymized tables into an internal database, plus Power BI / Excel front
ends. Foundation should take the **tables**, not their hosted Power BI
workspace, as the system of record.

Pick one landing method when the vendor packet arrives:

| Vendor delivers | Foundation action |
|---|---|
| SQL database / data extension | Azure SQL (or warehouse) + shortcut or mirror into `lake_house_buildermetrix` |
| Files (CSV / Parquet) in ADLS | Copy into `lake_house_buildermetrix` Files then tables, Workspace Identity |
| REST / API | Notebooks + `pipeline_buildermetrix_load` (schedule OFF until go-ahead) |
| Shared Power BI dataset only | Reject as SoT; ask for the SQL / lake extract |

## Do not

- Enable a schedule
- Run a first load without a named window
- Promote to Foundation until FD has a successful load and a table list
- Put vendor dashboards in `analytics/finance` as if they were Foundation IPE
- Treat BuilderMetrix benchmarks as SOX IPE unless Controller says so
- Touch Enterprise NEWSTAR / HBLive as part of this standup

## Need from Constellation / IT

1. Delivery method (SQL push, files, API)
2. Table list and grain (company vs industry-anonymized)
3. Refresh cadence
4. Auth (SQL login vs Entra vs Key Vault secret)
5. Whether GBP-specific ERP extract is included or only anonymized peer data

## Related

- Zonda analog: [`zonda-setup.md`](zonda-setup.md)
- NEWSTAR books path: DataSources `HBLive` / `SPLive` mirrors, then `warehouse_stage.transform`
