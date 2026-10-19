# Fabric CI/CD path (Foundation Development)

**Status:** IMPLEMENTED (pipeline YAML) / NOT LIVE-TESTED (fab apply)

## Scope

- Azure Pipeline: [`.azuredevops/pipelines/fabric-fd-deploy.yml`](../../.azuredevops/pipelines/fabric-fd-deploy.yml)
- Target workspace: **Foundation Development** only
- Production **Foundation** workspace requires a separate authorized pipeline and D12 item-level approval

## Intended tools

- `fabric-cicd` (ADOPT)
- `fab` CLI read-back after apply
- Policy gate: `foundation policy --action deploy --workspace "Foundation Development"`

## Approval

The `foundation-development-approval` Azure DevOps environment must require human approval.
No automatic production deployment.

## Live execution

Do not claim live Fabric deploy success until a run is executed with a configured service connection and evidence is recorded in the execution ledger.
