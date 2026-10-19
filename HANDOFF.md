# Handoff — shipped 2026-10-19

This file records what was in flight and how it landed. Another tool can use it without the prior chat.

## Product

Repo: `the-data-warrior-agent`  
Remote: `https://github.com/Rla102277/The-data-warrior-agent.git`  
Manuscript (doctrine): `https://github.com/Rla102277/the-data-warriors-manuscript`  
Identity: Matt-style skill system + Forge software factory. The manuscript is doctrine; this repo executes. Human is the Data Warrior. Roles (Deshi / Rōnin / Kensei) change collaboration style, never permissions.

Read before editing:

- `THE_WAY.md`
- `CLAUDE.md`
- `AGENTS.md`
- `SCROLL.md` (decisions D-011 through D-015)

## Git (after ship)

| Ref | Notes |
| --- | --- |
| Branch of record | `cursor/manuscript-parity`, rebased onto `origin/main` (includes README commit `6b98bdc`), then merged to `main` and pushed |
| Prior checkpoint | `1df7aff` “checkpoint before checking out main” (pre-rebase). Do not resume from `cursor/forge-neutral-evidence-gates` (`d045996`) |

## What landed on main

1. **Manuscript parity (SCROLL D-014)**  
   - `docs/PARITY.md`  
   - Skill/doc updates for Scroll, Battle Map, Chronicle, reviews, forge stop rules  
   - `tests/unit/test_parity_map.py`  
   - `scripts/verify.py` asserts the open-parity sentence  
   - **Verdict stays open:** do not mark host behavioral parity passed without a live transcript of `/know-the-ground` then `/the-forge`. Required sentence: “Behavioral parity across hosts is open”.

2. **Fabric removal (SCROLL D-015)**  
   - Deleted `forge/fabric/`, Fabric discovery adapter, `docs/FABRIC.md`, `fabric-first-foundation`, Fabric tests/fixtures  
   - Tool-neutral `forge/discovery/fixture.py` and `tests/fixtures/inventory/sample.yaml`  
   - Removed `fabric` extra / `dbt-fabric` / Fabric-only `httpx`  
   - Neutral `forge-default` profile; no Fabric MCP servers; no Fabric item-prefix law  
   - Agent role `fabric_engineer` → `builder`  
   - Ground/tool skills: do not assume a platform; bring tools after the ground names them

Generated jobs under `demos/local_orders/factory_jobs/` were removed from tracking (`.gitignore` already ignores that path). **Do not re-add them.**

## Still present (intentional)

The policy engine still has Foundation workspace rules (development allow, production deny, finance warehouse, Salesforce workspace). The user removed Fabric, not that engine. Do **not** import Foundation estate knowledge.

## Verify after pull

```bash
python3 scripts/verify.py
python3 -m unittest discover -s tests/warrior -v
# pytest: prefer pyenv 3.11.9 if system python3 has no pytest
/Users/randy/.pyenv/versions/3.11.9/bin/python -m pytest -q
```

Prior observation on 2026-10-19 before ship: verify 30 skills, warrior 12, pytest 93. Re-run after pull.

## Hard rules

- Do not reintroduce a vendor platform as a default profile, adapter, discovery path, or dependency.
- Tools are recorded on the ground and brought in only when the single action needs them.
- Do not import Foundation estate knowledge.
- Do not mark behavioral parity across hosts as passed without a live host transcript.
- Do not commit generated demo/job artifacts under `demos/local_orders/factory_jobs/`.
- Only commit when the user asks.

## Next challenge (from SCROLL)

Prove the mission in a live host trial: `/know-the-ground` refuses a tool-first ask, then `/the-forge` only after one action is on the Scroll.
