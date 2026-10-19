# Developer setup (Foundation SDK rebuild)

## Prerequisites

- Python 3.11+
- Git access to Azure DevOps `grbk/Foundation`
- For live Fabric work: Azure CLI + `ms-fabric-cli` (`fab`) with `az login` / `fab auth login`

## Install Foundation SDK (local)

```bash
cd /path/to/Foundation
python3 -m pip install -e ".[dev]"
foundation doctor
python -m pytest tests/unit -q
```

## Implemented CLI commands

| Command | Purpose |
|---|---|
| `foundation doctor` | Local SDK and convention check |
| `foundation inventory` | Fixture-based Fabric inventory |
| `foundation discover` | Fabric fixture and/or ADF JSON discovery |
| `foundation policy` | Evaluate policy decision |
| `foundation lineage` | ADF dependency impact |
| `foundation validate` | Validate ingestion metadata spec |

Commands not listed here are not claimed as operational.

## Jobsite factory

The existing Jobsite factory remains available:

```bash
make jobsite-setup
make jobsite-test
```

Jobsite is Foundation-owned tooling (Principle 1), not a separate product brand for long-term architecture.
