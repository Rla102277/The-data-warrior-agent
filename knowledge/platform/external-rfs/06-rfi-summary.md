# RFI summary (Request for Information)

**Purpose:** Market scan and capability assessment before a formal RFP/RFS.  
**Audience:** Integrators, SI partners, niche vendors (Fabric, dbt, Purview, Encompass, planning feeds)

## 1. Background (paste-ready)

Green Brick Partners operates a Microsoft Fabric F32 capacity in West US 3 with Azure SQL sources (NewStar ERP/Sales, BuildPro), Salesforce, Zonda, Dataverse, and emerging web scrape feeds. A multi-year **Foundation** program rebuilds the legacy GBP-Enterprise EDW (~90 pipelines, `dim_`/`fact_` naming) into **Foundation Development** with:

- Metadata-driven stage orchestration (`warehouse_stage`, `control.stage_load_config`)  
- dbt-owned analytics (`foundation` project)  
- Shared presentation lakehouse (`lake_house_analytics`)  
- D13 descriptive naming (`obt`, `det`, `sum`, `hist`, `map`)  
- Deployment pipeline to **Foundation** prod twin  

Title analytics (`title_booking_obt`, `title_communities_det`) are built. Mortgage (Encompass) and full planning (TM1) integration paths are in discovery.

Supporting documents: [`README.md`](README.md) and docs 01-05 in this folder.

## 2. Information requested

Responders should address the sections below. Green Brick may issue follow-up RFP to shortlisted vendors.

### A. Microsoft Fabric and Azure

1. Experience with Fabric deployment pipelines, workspace folders, and cross-workspace shortcuts.  
2. Approach to warehouse schema design (`raw`, `control`, `transform`, `analytics`) without dbo business tables.  
3. Workspace identity vs service principal vs Key Vault secret patterns for SQL and ADLS.  
4. Capacity planning for F32 or right-sizing recommendations.  
5. Private endpoint / VNet integration with Fabric and Azure SQL.

### B. dbt on Fabric

1. dbt-fabric project layout mirroring domain tags (`shared`, `operations`, `finance`, `title`).  
2. Testing strategy (`schema.yml`, freshness, custom tests on OBT grains).  
3. CI/CD without ODBC (SQL runner / Fabric job patterns).  
4. Handling unpublished `*_active` wrapper views vs published lakehouse contract.

### C. Stage transform parity

1. Method to prove `transform.sp_load_*` parity with legacy `EDW_Silver` procs.  
2. Experience with SCD2 `*_hist` patterns (`record_hash_key`, effective dating).  
3. Wave-based orchestration vs DAG engines; opinion on sequential ForEach tradeoff.

### D. Title domain

1. Experience with NewStar SPLive selection/booking data models.  
2. Proposed OBT grain for title pipeline reporting (`selection_id`).  
3. Semantic model rebinding approach from legacy `vw_rep_*` to `title_booking_obt`.

### E. Mortgage domain (future)

1. Encompass to Fabric patterns (SQL mirror vs API landing).  
2. PII handling and row-level security in Fabric semantic models.  
3. Join design to `sale` / `lot` without duplicate loan DET in planning tools.

### F. Planning / TM1 feeds

1. Experience feeding IBM Planning Analytics from Fabric lakehouse Delta tables.  
2. Recommended grain for actuals vs budget (`unit_budget_hist`, `sales_sum_monthly`).  
3. Latency and export mechanisms (ADLS CSV, PAfE, ODBC, TI processes).  
4. **Ask Green Brick:** list TM1 processes that must continue at cutover.

### G. Governance and observability

1. Purview scanning Fabric + Azure SQL + ADO git.  
2. Pipeline health dashboards; alerting integration.  
3. SOX-friendly promotion process (dev → prod) without prod destroy.

## 3. Question bank (optional attachments)

| # | Question |
|---|---|
| Q1 | How many homebuilder or real estate Fabric rebuilds have you delivered in 24 months? |
| Q2 | Do you employ certified Fabric Data Engineers? Count and location. |
| Q3 | Fixed-price vs T&M preference for a 6-month Foundation phase? |
| Q4 | Can you work additive-only in dev without touching GBP-Enterprise prod? |
| Q5 | Describe a dbt + semantic model handoff you performed with zero report downtime. |
| Q6 | How do you document OBT grain and test for fan-out duplicates? |
| Q7 | What is your Encompass integration reference architecture? |
| Q8 | How do you map TM1 dimensions to Fabric `operating_unit` / `fiscal_period`? |

## 4. Response format

| Section | Max length (suggested) |
|---|---|
| Company profile | 2 pages |
| Relevant case studies | 3 pages |
| Architecture responses A-G | 10 pages |
| Team and staffing | 2 pages |
| Commercial (indicative rates / bands) | 1 page |
| Risks and assumptions | 2 pages |

## 5. Evaluation (RFI phase)

| Criterion | Weight |
|---|---|
| Fabric + dbt depth | 30% |
| Homebuilder / ERP familiarity (NewStar, BuildPro) | 20% |
| Title / mortgage / planning integration experience | 20% |
| Governance and safe promotion | 15% |
| Staff availability and timezone | 15% |

Shortlist (typically 3-5 vendors) invited to RFP ([`07-rfp-summary.md`](07-rfp-summary.md)).

## 6. Schedule (template)

| Milestone | Date (TBD) |
|---|---|
| RFI issued | |
| Vendor Q&A deadline | |
| Responses due | |
| Shortlist notified | |
| RFP issued | |

## 7. Contacts and submission

*(Green Brick to insert procurement contact, portal, and NDA requirements.)*

## 8. Out of scope for RFI responses

- Binding fixed price (indicative only)  
- Production cutover commitments  
- Access to production write credentials  

See [`05-scope-in-scope-out-of-scope.md`](05-scope-in-scope-out-of-scope.md).
