# MVP acceptance

## Shipped capabilities
- Fourteen discoverable canonical skills with explicit "Use when" descriptions.
- Host-specific install for Cursor, Claude Code and Codex; installs THE_WAY.md and role configuration.
- Canonical-to-host generator with drift detection.
- Challenge and Scroll self-contained; Battle Map optional.
- Opinionated ingestion, CDC, SCD2, contract and Fabric guidance.
- Structural CI, installer tests, local headless behavioral trial harness.

## Release gates
- [ ] Latest GitHub Actions workflow completes successfully.
- [ ] Clone to a clean machine; install a selected skill for each supported host.
- [ ] In Cursor, verify the slash command invokes the intended skill.
- [ ] In Claude Code, run at least one authenticated headless behavioral trial and review transcript.
- [ ] Verify Scroll writes, contradiction supersession and cross-session resumption.
- [ ] Verify Battle Map does not invent progress.
- [ ] Verify role switch affects interaction but not permissions.

Do not call this behavior-validated until the unchecked gates have actual evidence. No credentials or live production access are required to install.
