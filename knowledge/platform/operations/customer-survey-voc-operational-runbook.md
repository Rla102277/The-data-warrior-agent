# Customer Survey VOC Operational Runbook

**Environment:** Foundation Development only

## Deploy control tables

```bash
python3 -u automation/deploy_customer_survey_intelligence_control.py
```

## Deploy dbt analytics views

```bash
cd dbt && dbt run --select customer_survey_response_statistical_det customer_survey_statistical_sum customer_survey_statistical_det customer_survey_comment_det customer_survey_theme_det customer_survey_voc_sum customer_survey_voc_review_det
cd dbt && dbt test --select customer_survey_statistical_sum customer_survey_comment_det
```

Or via SQL runner:

```bash
./dbt/deploy_via_sql_runner.sh
```

## Publish to lakehouse

Update `control.analytics_refresh_config` (git) then run `pipeline_operations_analytics_refresh` with `p_domain = operations`.

## Build VOC notebook and pipeline

```bash
python3 -u automation/build_customer_survey_voc_pipeline.py --dry-run
python3 -u automation/build_customer_survey_voc_pipeline.py
```

Run pipeline on demand only. **Do not enable schedule** without explicit instruction.

## Extend semantic model

```bash
python3 -u automation/rebuild_custsat_semantic_model.py --extend-statistical-voc --dry-run
python3 -u automation/rebuild_custsat_semantic_model.py --extend-statistical-voc --skip-report
```

## Reprocess comments

1. Truncate `analytics.customer_survey_voc_comment_stage` (FD only)
2. Re-run `pipeline_operations_customer_survey_voc`
3. Re-run analytics refresh for VOC models

## Rollback

1. Revert control seed versions in SQL files
2. Remove analytics_refresh_config rows for new models
3. Disable VOC pipeline
4. Redeploy prior semantic model from `fabric/build/custsat_obt_sm/`

## Review queue

Query `customer_survey_voc_review_det` where `review_status = PENDING`.  
Queue = Negative keyword labels or rating-sentiment conflict (not every comment).

Apply write-back without touching stage `classification_json`:

```bash
python3 -u automation/apply_customer_survey_voc_review.py \
  --comment-id <source_comment_id> --status CONFIRMED
```

Weekly operate checklist: [`customer-survey-weekly-operate.md`](customer-survey-weekly-operate.md).
