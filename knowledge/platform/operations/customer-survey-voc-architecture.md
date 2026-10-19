# Customer Survey VOC Architecture

**Workspace:** Foundation Development  
**Notebook:** `notebook_operations_customer_survey_voc`  
**Pipeline:** `pipeline_operations_customer_survey_voc` (schedule OFF)

## Flow

```
lake_house_analytics.operations.customer_survey_obt (Text rows)
  -> notebook_operations_customer_survey_voc
      eligibility + PII redaction + hash idempotency
      keyword rules. Fabric AI is not called.
  -> analytics.customer_survey_voc_comment_stage
  -> dbt customer_survey_comment_det / theme_det / voc_sum / voc_review_det
  -> lakehouse publish
  -> semantic_model_operations_customer_survey
```

## AI provider

- Config: `control.customer_survey_voc_config.ai_provider`
- Runtime: `KEYWORD_RULES` in `classify_by_keywords`. The notebook does not call Fabric AISQL, Azure OpenAI, or synapseml.
- Separate Fabric AI surface: `data_agent_operations_customer_survey` Copilot chat over the OBT (tenant EnableAOAI on). It does not write VOC labels.
- No plaintext secrets; Key Vault secret name in config only

## Idempotency

`normalized_comment_hash = SHA256(response_id, normalized redacted text, taxonomy_version, model_version)`

Unchanged hashes are skipped.

## Failure recovery

- Exceptions: `control.customer_survey_voc_exception_det`
- Run audit: `control.customer_survey_voc_run_det`
- Never log unredacted comment text

## Auth

Workspace identity + Key Vault (`gb-fabric-keyvault`). See `knowledge/operations/identity.md`.
