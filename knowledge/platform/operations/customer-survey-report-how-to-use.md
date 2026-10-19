# How to use the Customer Survey report

**Audience:** Division and operations leaders, plus anyone who will walk the Foundation Development report with them.  
**Workspace:** Foundation Development only. This is not the Operations production report.  
**Report:** `report_operations_customer_survey`  
**Open:** [Customer Survey report](https://app.fabric.microsoft.com/groups/40502864-6ece-49b5-807f-6f7c11d1b3e1/reports/9fdfa39b-edbd-45f3-aee1-e69e0db479f8/?experience=fabric-developer)

This writeup is the operating guide. It is not a metrics dictionary (that is the Metrics lexicon tab) and it is not a build plan.

---

## What this report is for

Use it to answer three different questions without mixing the answers:

1. **Are we on the company KPI?** Official experience % vs target. This is what operations already knows as Overall, Sales, Construction, Design, Lender, Escrow, Delivery, and Orientation.
2. **Is a community out of line with its peers, on enough sample?** Statistical Intelligence. Normalized 0-100 scores, z-score vs the operating unit, suppression when n is under 30.
3. **What are buyers writing?** Voice of Customer. Redacted comments plus keyword labels for sentiment, theme, urgency, and action.

The gauges stay official. The new pages do not replace them.

---

## Before you brief anyone

- Filters live on **Overview**. Set Date type, Period, Operating unit, and Survey there first. Those slicers stay in sync on the other tabs.
- If a number looks blank on Statistical cards, check **Stat Sample Count** and the Metrics lexicon. Mean, z-score, peer mean, and confidence interval go blank unless the visual is on rows where sample status is MET (n at least 30).
- Voice of Customer labels are **keyword rules**, not a language model. A comment with “delay” can land Negative even if the rest of the sentence is praise. Read the redacted text. Do not brief Net Sentiment as AI.
- Buyer email and phone are not on the VOC page or on Excel / OneDrive extracts.

---

## Page walk (left to right)

**Tutorial.** Opening page. Eight short sections and buttons into Overview, Statistical Intelligence, Voice of Customer, and the Metrics lexicon.

**Metrics lexicon.** Filter Family (Official KPI, Statistical Intelligence, Voice of Customer, Classification codes, Classifier). Use it when a card name is unclear. Forty-six rows: definition, formula, how to read, caveat, source.

**Overview.** Set the filters. The guide text lists what each later tab is for.

**Executive Scorecard.** Eight official gauges against KPI targets (MinGoal / MaxGoal bands). Green / yellow / red here is vs target, not vs peer z-score. The strip under the gauges is a glance at normalized score, sample count, net sentiment, and the human review queue. A community can be green on the gauge and ALERT on Statistical Intelligence at the same time. That is expected.

**Community.** Official % matrices for operating unit and project. The lower matrix is peer benchmarks (project vs operating unit, sample MET): score, z-score, peer mean, confidence interval, n.

**Statistical Intelligence.** Four cards (mean, z-score, sample count, peer mean). Main matrix is project vs operating unit. Significant movers table is ALERT and MET only. Period-change table is current calendar month vs prior month, and only when both months MET. First FD load had 18 paired period rows, so that table will look thin until more months qualify.

**Voice of Customer.** Net sentiment, comment count, action-required, review queue. Theme matrix. Redacted comment table. Human review queue is every keyword-Negative comment (23 on the first classify pass). Theme defaults to Overall Satisfaction unless the text has construction/build or sales/contract.

**Question.** Official question scores plus goal bands. Period-comparison table from the statistical detail (mean change, effect size, practical flag, reason).

**Hidden pages.** Comments, Responses, Word Cloud, Survey Rate, and row-level Detail are not on the tab strip. Open them from **Show details** on Executive, Community, or Question.

---

## How to run a 15-minute review

1. Overview: pick the survey bucket (Move-In is the usual starting point) and the period you will defend in the room.
2. Executive: read the eight gauges. Note any category below target. Ignore the statistical strip until step 4.
3. Community: find the operating unit, then the projects that pull that unit around.
4. Statistical Intelligence: keep the MET filter in mind. Rank only rows that have a z-score. ALERT means |z| at least 2 vs the peer group. Do not treat a high official % on n under 30 as a peer outlier.
5. Voice of Customer: open the review queue and the theme matrix for the same OU / communities. Read comments. Treat keyword tags as a spotlight, not a verdict.
6. Question: if a category gauge moved, use the question matrix and the period table to see which item changed.
7. If someone asks “what does this card mean?”, go to Metrics lexicon instead of inventing a definition.

---

## Export

From hidden detail pages (Comments, Responses, Detail, Questions):

- **Export to Excel** downloads an XLSX after sign-in.
- **Export to OneDrive** writes to `/Foundation Exports`.

Extracts omit buyer email and phone. Choose one value per export filter if you use the paginated path. Multi-select on that path is not supported.

---

## What not to do

- Do not replace Overall % (or the other seven official %) with Stat Mean Score in a scorecard or email.
- Do not rank suppressed samples.
- Do not say the comments were classified by Fabric AI. They were not. Copilot on `data_agent_operations_customer_survey` is a separate chat over ratings. It does not write VOC labels.
- Do not enable the VOC pipeline schedule from this guide. On-demand only, and only in Foundation Development.
- Do not treat this report as production. Operations production is a different report and was not changed.
