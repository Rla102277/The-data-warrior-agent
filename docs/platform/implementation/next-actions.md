# Next actions

**Updated:** 2026-10-16 (post approve/rework CLI wave)

Forge Line M0-M11 remain implemented. This wave added human gate CLI commands.

## Do next

1. Register ADO SSH key (optional; HTTPS+az already works for push).
2. Create Azure DevOps environment `foundation-development-approval` with human gate for `fabric-fd-deploy.yml`.
3. Live FD `fabric-cicd` apply when service connection is ready; record ledger evidence (do not claim success until run).
4. Redirect Jobsite docs in the legacy Foundation checkout to Foundation 2.0.
5. Expand specialist agents only when the thin set (spec/builder/three reviewers/approver) is insufficient.

## Commands

```bash
make setup
make test
make doctor
make demo
make factory-dashboard   # http://127.0.0.1:8765/dashboard.html

forge job create --title "..."
forge job approve --job-id <id> --authorized
forge job rework --job-id <id> --note "fix D13 name"
foundation modernize --adf tests/fixtures/adf/sample_pipeline.json
```

## Explicit non-goals

- ADEF brand or `adef` CLI
- Retail360 / medallion object names in live Fabric
- Closing D2 / D3 / D11 without decision records
- Auto production deploy
