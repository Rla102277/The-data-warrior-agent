# Customer Survey VOC Report Specification

**Report:** `report_operations_customer_survey`  
**Status:** VOC page is a visible tab on `report_operations_customer_survey`. Comment labels are keyword rules v2, not a language model.

## Voice of Customer page

Visible tab. Redacted comments only.

| Section | Visuals |
|---------|---------|
| Executive summary | `Net Sentiment`, `VOC Comment Count`, `Action-Required Comments` |
| Theme analysis | Matrix of `theme_code` x `comment_count` from `customer_survey_voc_sum` |
| Risk queue | Table from `customer_survey_voc_review_det` |
| Comment detail | `redacted_response_text` only; authorized users |

## Measures (semantic model)

| Measure | Folder |
|---------|--------|
| Net Sentiment | Voice of Customer\\Sentiment |
| Action-Required Comments | Voice of Customer\\Risk |
| High Urgency Comments | Voice of Customer\\Risk |
| VOC Comment Count | Voice of Customer\\Volume |
| Human Review Queue | Voice of Customer\\Review |

## Non-goals

- No buyer PII on aggregate pages
