# Foundation Market Intelligence MCP

Cursor stdio MCP for Foundation Market Intelligence. Package:
`automation/mcp_market_intelligence`. Entry:
`python3 -m automation.mcp_market_intelligence`.

**Workspace:** Foundation Development only
(`40502864-6ece-49b5-807f-6f7c11d1b3e1`).  
**SQL:** `warehouse_stage` on the FD Fabric SQL endpoint.  
**Pipeline:** `pipeline_web_scrape` (`01a78eb2-c176-4604-88bb-974700cb991d`) only.

Product ops: [`foundation-market-intelligence.md`](foundation-market-intelligence.md).  
Smoke pack: `automation/run_market_intelligence_mvp_smoke.py`.

## Safety

- FD-only hard gates (workspace id, host, database, pipeline item).
- No Foundation (prod), no Enterprise, no other workspaces.
- No Dataverse write tools.
- No free-form SQL tool (parameterized / allowlisted filters only).
- `mi_start_scrape` starts one on-demand pipeline job. It does **not** enable
  or change Fabric schedules.
- Default row limit 50, hard max 200.
- Auth: `az account get-access-token` for SQL (`database.windows.net`) and
  Fabric API (same pattern as the MI smoke script).

## Tools (nine)

| Tool | Backing |
|---|---|
| `mi_coverage_summary` | `analytics.web_scrape_coverage_obt` counts by `coverage_status` |
| `mi_coverage_list` | Same view; filter status / community / builder |
| `mi_listings` | `analytics.competitor_listing_obt` (require community, builder, or source_group) |
| `mi_peer_position` | `analytics.competitor_position_obt` (community or source_group) |
| `mi_what_moved` | `analytics.web_listing_change_det` |
| `mi_scrape_health` | `control.web_scrape_run_det` + fingerprint stamps on `control.web_scrape_source` |
| `mi_pipeline_runs` | Fabric jobs API on FD `pipeline_web_scrape` |
| `mi_start_scrape` | POST one FD `pipeline_web_scrape` job instance |
| `mi_smoke` | Runs `automation/run_market_intelligence_mvp_smoke.py` |

## Cursor `mcp.json` snippet

Local operator config only. Do **not** commit secrets or this file into git.
Adjust `cwd` to your Foundation clone path.

```json
{
  "mcpServers": {
    "foundation-market-intelligence": {
      "command": "python3",
      "args": ["-m", "automation.mcp_market_intelligence"],
      "cwd": "/Users/YOU/Documents/Projects/Foundation"
    }
  }
}
```

Requires: Azure CLI logged in (`az login`), ODBC Driver 18, `pyodbc`, and
the `mcp` Python package (2.x) available to that `python3`. Prefer the repo
`.venv` when present:

```json
{
  "mcpServers": {
    "foundation-market-intelligence": {
      "command": "/Users/YOU/Documents/Projects/Foundation/.venv/bin/python",
      "args": ["-m", "automation.mcp_market_intelligence"],
      "cwd": "/Users/YOU/Documents/Projects/Foundation"
    }
  }
}
```

## Related

- Agent setup MCP table: [`agent-setup.md`](agent-setup.md)
- Web scrape ops: [`web-scrape-user-manual.md`](web-scrape-user-manual.md)
- Decision D19 (web scrape landing + MI consumption addendum):
  [`../decisions/README.md`](../decisions/README.md)
