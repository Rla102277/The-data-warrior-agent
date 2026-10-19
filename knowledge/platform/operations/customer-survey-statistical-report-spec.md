# Customer Survey Statistical Report Specification

**Report:** `report_operations_customer_survey` (FD)  
**Semantic model:** `semantic_model_operations_customer_survey`  
**Status:** Live in FD 2026-09-03. Visible tab. Tooltips on peer matrix. n = 30 and 0-10 scale approved Wave 0. Period table includes Welch p and BH-FDR p.

## Executive Scorecard

Add cards (Statistical Intelligence folder):

| Visual | Measure / field | Notes |
|--------|-----------------|-------|
| Enterprise normalized score | `Stat Mean Score` filtered to enterprise peer | Tooltip: peer definition |
| Period change | `customer_survey_statistical_det.mean_change` | Prior month comparison |
| Reliability | `Stat Sample Count` | Show suppression when n < 30 |
| Significant movers | Table of `classification = ALERT` | Top z-scores |

## Community page

| Visual | Content |
|--------|---------|
| Matrix extension | `Stat Z-Score`, `Stat Peer Mean`, `Stat CI Lower/Upper` by project |
| Suppression | Matrix filtered to `minimum_sample_status = MET` |
| Tooltip | Peer group, sample status, class, n |

Stabilized-score toggle is not built. `enable_stabilized_score` remains 0.

## Question page

| Visual | Content |
|--------|---------|
| Detail table | `effect_size`, `practical_significance_flag`, `comparison_status_reason` |
| Tooltip | Peer group type, sample size, suppression reason |

## Tooltips (assignment 3.12)

Peer group type, sample status, classification, and n on Statistical Intelligence and Community peer matrices.

## Non-goals

- Do not replace official category `%` measures
