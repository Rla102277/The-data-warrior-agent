# Customer Survey Semantic Model Extension Spec

**Model:** `semantic_model_operations_customer_survey`  
**Flag:** `--extend-statistical-voc` on `automation/rebuild_custsat_semantic_model.py`

## New tables

| Table | Source | Purpose |
|-------|--------|---------|
| `customer_survey_statistical_sum` | `lake_house_analytics.operations` | Peer benchmarks, z-scores, CI |
| `customer_survey_statistical_det` | same | Period comparisons |
| `customer_survey_voc_sum` | same | Theme/sentiment aggregates |
| `customer_survey_comment_det` | same | Redacted comment detail |

## Relationships

| From | To | Column |
|------|-----|--------|
| `customer_survey_statistical_sum.period_start_date` | `calendar.full_date` | inactive date table |
| `customer_survey_voc_sum.period_start_date` | `calendar.full_date` | inactive date table |

## Statistical Intelligence measures

| Measure | Expression summary |
|---------|-------------------|
| Stat Mean Score | AVERAGE when `minimum_sample_status = MET` |
| Stat Z-Score | AVERAGE z_score when sample met |
| Stat Peer Mean | Peer benchmark mean |
| Stat Sample Count | SUM response_count |
| Stat CI Lower / Upper | CI bounds when sample met |

## Voice of Customer measures

| Measure | Expression summary |
|---------|-------------------|
| Net Sentiment | AVERAGE net_sentiment_ratio |
| Action-Required Comments | SUM action_required_count |
| High Urgency Comments | SUM high_urgency_count |
| VOC Comment Count | SUM comment_count |
| Human Review Queue | SUM human_review_count |

## Deployment

FD only. Use `--skip-report` when rebinding report is not needed.
