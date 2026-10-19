# dbt discovery

Implemented commands:

```bash
foundation dbt discover --manifest dbt/target/manifest.json
foundation dbt lineage --manifest dbt/target/manifest.json --model sale_obt
foundation dbt validate --manifest dbt/target/manifest.json
```

Behavior:

- Reads `manifest.json` (and `catalog.json` when present).
- Does not overwrite dbt models.
- Flags banned naming tokens (`dim_`, `fact_`, `vw_`, tool acronyms).
- Treats D19 `market_dim_*` models as approved exceptions.
- Builds a dependency graph for impact analysis.

Evidence labels: inventory from a local manifest is Confirmed for repository contents, not proof of live warehouse correctness.
