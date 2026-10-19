# Customer Survey Statistical Methodology

**Workspace:** Foundation Development  
**Models:** `customer_survey_response_statistical_det`, `customer_survey_statistical_sum`, `customer_survey_statistical_det`

## Normalized score

Rating responses (`question_type_name = 'Rating'`) are mapped to a 0-100 scale using `control.customer_survey_question_scale_map`:

- Forward scored: `(rating - min) / (max - min) * 100`
- Reverse scored: `(max - rating) / (max - min) * 100`
- Invalid when outside scale bounds or non-rating type

## Peer benchmarks

`customer_survey_statistical_sum` publishes:

| peer_group_type | Entity | Peer |
|-----------------|--------|------|
| `PROJECT_VS_OPERATING_UNIT` | Project | Operating unit mean for same question/survey/period |
| `OPERATING_UNIT_VS_ENTERPRISE` | Operating unit | Enterprise mean |

Z-score: `(entity_mean - peer_mean) / peer_stddev` when sample and variance requirements are met.

## Confidence intervals

Normal approximation: `mean +/- 1.96 * stddev / sqrt(n)` at 95% confidence (`confidence_level = 0.95` in config). Null when `minimum_sample_status = SUPPRESSED`.

## Small sample policy

Default `minimum_sample_size = 30` (configurable in `control.customer_survey_statistical_config`). Below threshold:

- Z-score is null
- `minimum_sample_status = SUPPRESSED`
- Semantic model measures return `BLANK()`

## Stabilized score

Optional shrinkage toward peer mean when `enable_stabilized_score = 1`:

`(mean * n + peer_mean * prior_weight) / (n + prior_weight)`

Both raw and stabilized means are exposed.

## Significance testing

`customer_survey_statistical_det` compares current vs prior calendar month using a Welch t statistic. Because both months are MET (n >= 30), the two-sided p-value is the standard-normal tail of that t (Hastings AS 26.2.17). It is not an exact Student-t p with Welch-Satterthwaite degrees of freedom.

`statistically_significant_change_flag` is 1 when BH-FDR `adjusted_p_value` < `alpha` (0.05). Practical significance stays a separate 5-point flag.

## FDR

Family: all entities on the same `question_id` + `survey_name` + `peer_group_type` + `current_period_start`. Method BH-FDR. `fdr_family_size` is m in p * m / rank.
