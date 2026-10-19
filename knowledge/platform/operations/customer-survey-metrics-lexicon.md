# Customer Survey Metrics Lexicon

**Workspace:** Foundation Development only
**Report page:** Metrics lexicon on `report_operations_customer_survey`
**Semantic table:** `customer_survey_metric_lexicon` (calculated DATATABLE)

Official category % measures stay the scorecard. Statistical Intelligence and Voice of Customer are complementary. They do not replace Overall %, Sales %, or the other official gauges.

## Fabric AI (read this first)

Three different things get called Fabric AI in this project:

1. **VOC comment labels (live):** keyword rules in `notebook_operations_customer_survey_voc.classify_by_keywords`. Not a language model.
2. **VOC config:** `control.customer_survey_voc_config.ai_provider` is `KEYWORD_RULES` / `keyword-rules-v1`. Older rows may still say FABRIC_AI. The notebook never calls Fabric AISQL, Azure OpenAI, or synapseml.
3. **Data Agent Copilot (separate, real tenant AI):** `data_agent_operations_customer_survey` uses the Copilot pane with Azure OpenAI enabled on the capacity. It chats over `customer_survey_obt`. It does not classify comments into VOC tables.

Do not brief VOC sentiment as model output. Pipeline schedule stays OFF.

## How official % differs from Stat Mean Score

| | Official % | Stat Mean Score |
|---|---|---|
| Scale | Migrated KPI percent | Normalized 0-100 from the scale map |
| Suppression | None | BLANK unless n >= 30 (MET) |
| Benchmark | KPI target (MinGoal / MaxGoal) | Peer mean (project vs OU, or OU vs enterprise) |
| Typical visual | Executive gauges | Statistical Intelligence cards and matrices |

## Rows

### Official KPI

| Metric | Definition | Formula | How to read | Caveat | Source |
|---|---|---|---|---|---|
| Overall % | Official overall experience score. Primary gauge on Executive Scorecard. | Migrated DIM_Measures DAX on customer_survey_obt rating rows, filtered by DateType and Period. | This is the company KPI. Use it for targets, status color, and ranking that operations already knows. | Do not replace with Stat Mean Score. The two scales are not interchangeable. | `customer_survey_obt` |
| Sales % | Official sales-experience category score. | Same OBT rating pattern as Overall %, restricted to the sales experience question set. | Read with Survey Count. A high % on a thin sample is still the official KPI, not a peer ALERT. | Statistical z-score for sales questions lives on Statistical Intelligence, not this measure. | `customer_survey_obt` |
| Construction % | Official construction-experience category score. | OBT rating DAX for the construction experience question set. | Pair with Voice of Customer construction themes when the gauge moves. | Official % is not a z-score and is not suppressed at n under 30. | `customer_survey_obt` |
| Design % | Official design and selections category score. | OBT rating DAX for the design question set. | Use Executive and Community matrices for this number. | Not replaced by normalized 0-100 statistical scores. | `customer_survey_obt` |
| Lender % | Official lender-experience category score. | OBT rating DAX for the lender question set. | Lender comments in VOC use theme LENDER_MORTGAGE, which is a different grain. | Category % and VOC theme counts will not match 1:1. | `customer_survey_obt` |
| Escrow % | Official escrow-experience category score. | OBT rating DAX for the escrow question set. | Closing comments often land in VOC theme CLOSING_TITLE rather than this gauge. | Do not treat VOC theme volume as the escrow KPI. | `customer_survey_obt` |
| Home Delivery % | Official home-delivery / delivery-experience category score. Gauge label is Delivery. | OBT rating DAX for the home delivery question set. | Same measure drives the Delivery gauge and Community matrix column. | Also aliased as Home Delivery 1-100 (percent times 100) in the model. | `customer_survey_obt` |
| Orientation % | Official orientation-experience category score. | OBT rating DAX for the orientation question set. | Move-in comments in VOC use ORIENTATION_MOVEIN. | Official % stays on Executive, Community, and Question. | `customer_survey_obt` |
| Key Metrics % | Composite official score across the key-metrics question bundle. | OBT rating DAX; also exposed as Key Metrics 1-100. | Not one of the eight Executive gauges. Use when a visual binds this measure. | Do not confuse with GPA % or Overall %. | `customer_survey_obt` |
| GPA % | Composite GPA-style official score from the migrated measure set. | OBT rating DAX; also exposed as GPA 1-100. | Not one of the eight Executive gauges. | Do not use as a substitute for Overall % in KPI reviews. | `customer_survey_obt` |
| Survey Count | How many surveys sit under the current filters. | Distinct survey_response_id on customer_survey_obt (not response_id, which is question-level). | Always check this next to a % or a z-score. Thin n makes both noisier. | OBT Response Count is question-level and will be larger than Survey Count. | `customer_survey_obt` |
| MinGoal / MaxGoal | Disconnected slicer tables that set the green / yellow / red bands on official gauges. | Calculated tables MinGoal and MaxGoal in the semantic model. | Change the slicer on Overview or Question. It does not change statistical thresholds. | Statistical ALERT uses z-score thresholds in control config, not these goal bands. | `MinGoal, MaxGoal` |
| KPI target / status | Gauge target line and status color for each official experience measure. | Measures such as KPI - Overall Experience Target and KPI - Overall Experience Status. | Green / yellow / red on Executive is vs KPI target, not vs peer z-score. | A community can be green on the gauge and ALERT on Statistical Intelligence at the same time. | `customer_survey_obt` |

### Statistical Intelligence

| Metric | Definition | Formula | How to read | Caveat | Source |
|---|---|---|---|---|---|
| Normalized score | Each valid rating mapped to 0-100 so questions can be compared on one scale. | Forward: (rating - min) / (max - min) * 100. Reverse: (max - rating) / (max - min) * 100. | This is the input to Stat Mean Score. It is not the official category %. | Wave 0 approved 0-10 forward score for all Rating questions. Invalid or non-rating rows are excluded. | `customer_survey_response_statistical_det` |
| Stat Mean Score | Average normalized 0-100 score for the entity, question, survey, and period in context. | AVERAGE(mean_score) when minimum_sample_status is MET; otherwise BLANK. | Cards go blank at grand total unless the visual is filtered to MET. That is intentional. | Not Overall %. Do not rank suppressed rows (n under 30). | `customer_survey_statistical_sum` |
| Stat Z-Score | How many peer standard deviations the entity mean sits from the peer mean. | (entity_mean - peer_mean) / peer_stddev when n meets minimum and variance is non-zero. | Near 0 is in line with peers. Negative is below peers. Absolute value 1 is WARNING, 2 is ALERT. | BLANK when SUPPRESSED or INSUFFICIENT_VARIANCE. Sign matters; below-peer ALERTs are the risk. | `customer_survey_statistical_sum` |
| Stat Peer Mean | Benchmark mean for the chosen peer group. | AVERAGE(peer_mean_score) when sample status is MET. | Read the peer_group_type column. Project vs OU is not the same as OU vs enterprise. | Peer mean is not an official KPI target. | `customer_survey_statistical_sum` |
| Stat Sample Count | Rating responses in the statistical grain (entity x question x survey x period x peer group). | SUM(response_count). Shown even when the mean is suppressed. | Use this to see why a score is blank. n under 30 is SUPPRESSED. See Why n = 30. | This is not Survey Count. One survey can contribute many rating rows. | `customer_survey_statistical_sum` |
| Stat CI Lower / Upper | 95% confidence interval around the entity mean. | mean +/- 1.96 * stddev / sqrt(n). Null when sample is SUPPRESSED. | Wide interval means the mean is noisy. Overlapping intervals with the peer mean are not an ALERT by themselves. | Normal approximation; not a bootstrap. Blank at totals unless filtered to MET. | `customer_survey_statistical_sum` |
| minimum_sample_status | Whether the row is allowed into z-score and CI visuals. | MET when response_count >= 30 (control.customer_survey_statistical_config). Else SUPPRESSED. | Filter matrices to MET. Do not rank SUPPRESSED communities. | n = 30 is Wave 0 approved. See Why n = 30. | `customer_survey_statistical_sum` |
| Why n = 30 | Approved floor for publishing a z-score and a 95% CI. | CI uses mean +/- 1.96 * sd / sqrt(n). Z-score uses the peer standard deviation. Both assume the sample mean is close to normal. | n = 30 is the conventional central-limit floor for that approximation. Below 30 the mean can still exist, but we hide z and CI (SUPPRESSED). | Signed Wave 0 on 2026-09-03. It is a policy choice, not a unique Green Brick scientific law. Changing it changes who can be ranked. | `control.customer_survey_statistical_config` |
| Approved rating scale | Every Rating question is mapped 0 to 10, forward scored. | normalized = (rating - 0) / (10 - 0) * 100. scale_status = APPROVED. | This is the wired scale for Statistical Intelligence. Official category % measures do not use this map. | Wave 0 signed 2026-09-03. Observed OBT ratings sit on 0-10. Reverse-score stays off until a later signed change. | `control.customer_survey_question_scale_map` |
| classification | Peer-movement class for a statistical row. | INSUFFICIENT_VARIANCE, then INSUFFICIENT_SAMPLE, then ALERT (\|z\|>=2), WARNING (\|z\|>=1), else NORMAL. | The Significant movers table is filtered to ALERT and MET. | ALERT is vs peers, not vs MinGoal. Official gauges can still be green. | `customer_survey_statistical_sum` |
| peer_group_type | Which benchmark the z-score uses. | PROJECT_VS_OPERATING_UNIT or OPERATING_UNIT_VS_ENTERPRISE. | Community page and the main stats matrix use project vs operating unit. | Do not mix the two peer groups in one ranking. | `customer_survey_statistical_sum` |
| mean_change | This calendar month mean minus prior calendar month mean (normalized 0-100). | current_mean_score - prior_mean_score on paired MET rows only. | Only rows with both months MET appear on statistical_det. | Read p_value and adjusted_p_value on the same row. Practical flag is separate. | `customer_survey_statistical_det` |
| effect_size | Relative period change vs the prior mean. | (current - prior) / \|prior\| when prior is non-zero. | Use with mean_change. A large percent of a tiny prior mean can look dramatic. | Not Cohen's d. Practical flag uses a 5-point absolute threshold from config. | `customer_survey_statistical_det` |
| practical_significance_flag | Whether the absolute mean change clears the configured practical threshold (0.05 on the 0-100 scale, i.e. 5 points). | 1 when abs(mean_change) >= practical_change_threshold. | 1 means the absolute change cleared 5 points on the 0-100 scale. | Not the same as statistically_significant_change_flag, which uses BH-FDR adjusted p < 0.05. | `customer_survey_statistical_det` |
| comparison_status_reason | Why a period pair was or was not compared. | COMPARED, INSUFFICIENT_SAMPLE, or INSUFFICIENT_VARIANCE. | If you expected a row and it is missing, the prior month likely failed MET. | Join is prior month = DATEADD(MONTH, -1, current period_start_date) on first-of-month dates. | `customer_survey_statistical_det` |
| p_value | Two-sided probability that a Welch t this large (or larger) occurs if the two month means were equal. | Welch t, then standard-normal two-sided tail (Hastings AS 26.2.17). Used because both months are MET (n >= 30), so t is treated as z. | Small p means the month-to-month mean change is unlikely under no-change. Read adjusted_p_value for the FDR-controlled claim. | This is not a Student-t exact p with Welch-Satterthwaite df. It is the normal approximation appropriate to the n = 30 policy. | `customer_survey_statistical_det` |
| adjusted_p_value | Benjamini-Hochberg FDR p-value inside the comparison family. | Family = all entities on the same question + survey + peer_group_type + current month. p_adj(i) = min_{j>=i} (p(j) * m / j), capped at 1. | Use this, not raw p, when you scan many communities on one question. statistically_significant_change_flag is adjusted_p < 0.05. | Family is not all questions in a community. Do not mix families when counting how many tests were run. | `customer_survey_statistical_det` |
| stabilized_mean_score | Optional shrinkage of the entity mean toward the peer mean. | (mean * n + peer_mean * prior_weight) / (n + prior_weight) when enable_stabilized_score = 1. | Config currently has enable_stabilized_score = 0, so this equals the raw mean. | Do not report shrinkage as live until the flag is approved on. | `customer_survey_statistical_sum` |

### Voice of Customer

| Metric | Definition | Formula | How to read | Caveat | Source |
|---|---|---|---|---|---|
| Net Sentiment | Share positive minus share negative among eligible classified comments. | positive/n - negative/n, then AVERAGE of net_sentiment_ratio in DAX. | 0 is balanced. +1 would be all positive. First FD run sat near +0.23. | Labels come from keyword rules, not a large language model. Neutral is the default. | `customer_survey_voc_sum` |
| VOC Comment Count | Eligible free-text comments in the VOC grain (OU x project x survey x period x theme). | SUM(comment_count) from voc_sum (eligible comments only). | First FD classify pass: 1371 comments. OBT text rows are more; ineligible/empty are dropped. | Not Survey Count and not OBT Response Count. | `customer_survey_voc_sum` |
| Action-Required Comments | Comments tagged ACTION_REQUIRED. | Keyword rule: sentiment NEGATIVE and urgency HIGH. SUM(action_required_count). | This is a queue, not an official KPI. Open the comment and the scorecard together. | HIGH urgency only if the text contains urgent, immediately, asap, or critical. | `customer_survey_voc_sum` |
| High Urgency Comments | Comments tagged HIGH or CRITICAL urgency. | SUM(high_urgency_count). CRITICAL is reserved; the keyword classifier currently emits LOW or HIGH. | Urgency is independent of theme. A polite delay complaint may stay LOW. | Keyword list is small. Absence of those words does not mean the buyer is calm. | `customer_survey_voc_sum` |
| Human Review Queue | Comments flagged for a person to read. | Keyword rule: every NEGATIVE sentiment. SUM(human_review_count). | 23 comments in the first FD run. Confidence is not the trigger (it is fixed at 0.55). | Config min_confidence_threshold is 0.60 but is not what fills this queue today. | `customer_survey_voc_sum` |
| redacted_response_text | Comment text after regex redaction of email, phone, and SSN-shaped tokens. | notebook_operations_customer_survey_voc redact_pii, then stage and comment_det. | This is the only comment body on the VOC page. Buyer email, phone, and address are omitted. | Redaction is pattern-based. Names and street addresses may still appear. | `customer_survey_comment_det` |
| sentiment_code | POSITIVE, NEGATIVE, or NEUTRAL label on a comment. | POSITIVE if great/excellent/love/amazing. NEGATIVE if bad/terrible/awful/delay/problem. Else NEUTRAL. | Default is Neutral. Mixed is in the sum table but the classifier does not emit MIXED yet. | Not Fabric AI. See Classifier family. | `customer_survey_comment_det` |
| primary_theme_code | Single primary theme from the 11-code taxonomy. | First matching v2 list: warranty, construction, design, schedule, closing, orientation, lender, amenity, sales. Else OVERALL_SATISFACTION. | Theme matrix on the VOC page is this code. Secondary matches are comma-separated. | Still keyword rules. A comment without those words stays Overall Satisfaction. | `control.customer_survey_theme_map` |
| journey_stage | Survey bucket used as journey context (Move-In, Mid-Year, Year-End, Closing). | RULES_FIRST: survey_name, else question_category, else UNKNOWN. Not AI_INFERENCE. | Use it as a filter, not as a model-inferred stage. | Config journey_stage_method is RULES_FIRST. | `customer_survey_comment_det` |
| confidence_score | Classifier self-reported confidence. | Fixed 0.55 on every keyword-classified comment. | Do not rank comments by confidence. It does not vary. | Will only become meaningful if a real model is wired. | `customer_survey_comment_det` |

### Classification codes

| Metric | Definition | Formula | How to read | Caveat | Source |
|---|---|---|---|---|---|
| MET | Sample size meets the statistical minimum (30). | response_count >= minimum_sample_size. | Required filter for Stat Mean Score, Z-Score, Peer Mean, and CI cards. | Official % measures ignore this flag. | `customer_survey_statistical_sum` |
| SUPPRESSED | Sample below 30. Mean, z, and CI are hidden in DAX. | minimum_sample_status when n < 30. | You can still see Stat Sample Count. | Do not treat a suppressed official % as a peer outlier. | `customer_survey_statistical_sum` |
| ALERT / WARNING / NORMAL | Peer z-score bands after sample and variance checks. | \|z\| >= 2 ALERT; \|z\| >= 1 WARNING; else NORMAL. | ALERT is the Significant movers table. WARNING is visible on the full stats matrix if you remove the ALERT filter. | Thresholds are in control.customer_survey_statistical_config. | `customer_survey_statistical_sum` |
| INSUFFICIENT_SAMPLE / VARIANCE | Could not compute a peer class. | INSUFFICIENT_SAMPLE when n < 30. INSUFFICIENT_VARIANCE when stddev is 0 or null. | All answers the same (or n too small) cannot produce a z-score. | Period comparisons use the same reasons on comparison_status_reason. | `customer_survey_statistical_sum` |
| POSITIVE / NEGATIVE / NEUTRAL | VOC sentiment vocabulary. | See sentiment_code. MIXED is counted in voc_sum but not assigned by the keyword classifier. | Net Sentiment uses only POSITIVE and NEGATIVE shares. | Keyword collision: a comment with both excellent and delay becomes NEGATIVE (delay is applied second). | `customer_survey_comment_det` |
| ACTION_REQUIRED / MONITOR | VOC action vocabulary. | ACTION_REQUIRED only when NEGATIVE and HIGH. Otherwise MONITOR. | MONITOR is the default, including all Neutral and Positive comments. | Not a work-order system. It is a report queue. | `customer_survey_comment_det` |

### Classifier

| Metric | Definition | Formula | How to read | Caveat | Source |
|---|---|---|---|---|---|
| Keyword rules | What actually labels comments in Foundation Development today. | classify_by_keywords() in notebook_operations_customer_survey_voc. Deterministic substring checks. | Treat VOC as a keyword spotlight, then read the redacted comment. Do not brief executives as if a model read the text. | confidence_score is always 0.55. Pipeline schedule is OFF. | `notebook_operations_customer_survey_voc` |
| Fabric AI (not wired) | Intended future provider for comment classification. Not called at runtime. | classify_comment() calls classify_by_keywords only. No AISQL, no Azure OpenAI chat, no synapseml call. | If a visual or old row says FABRIC_AI, that is a config label, not evidence a model ran. | Do not enable the VOC pipeline schedule until a real provider is approved. | `control.customer_survey_voc_config` |
| Fabric Data Agent Copilot | Separate Fabric AI surface: chat over customer_survey_obt in the Copilot pane. | data_agent_operations_customer_survey. Tenant EnableAOAI is on (West US 3). Uses CUs. | Ask questions about ratings and counts there. It does not write VOC sentiment or themes. | Not the VOC pipeline. Not Power BI report Copilot. Not promoted to Foundation prod. | `data_agent_operations_customer_survey` |

## Related docs

- [Statistical methodology](customer-survey-statistical-methodology.md)
- [Theme taxonomy](customer-survey-theme-taxonomy.md)
- [VOC architecture](customer-survey-voc-architecture.md)
- [CustSat Copilot POC](copilot-custsat-poc.md)
