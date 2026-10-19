# Local orders demo (Foundation layers)

Synthetic local demonstration of Forge Line. Uses DuckDB/Python.
Does **not** deploy to live Fabric. Layer folders are `raw` / `stage` / `transform` / `analytics`
(not bronze/silver/gold). Not a Retail360 product brand.

```bash
forge job demo
# or
python -m demos.local_orders.run_demo
```

Independent expected aggregates live in `expected_aggregates.json` and must not be
computed by the transformation step that is under test.
