# Customer Survey Theme Taxonomy

**Table:** `control.customer_survey_theme_map`  
**Version:** 1

| theme_code | theme_name | category |
|------------|------------|----------|
| SALES_EXPERIENCE | Sales experience | JOURNEY |
| DESIGN_SELECTION | Design and selections | JOURNEY |
| CONSTRUCTION_QUALITY | Construction quality | JOURNEY |
| SCHEDULE_COMMUNICATION | Schedule and communication | JOURNEY |
| CLOSING_TITLE | Closing and title | JOURNEY |
| ORIENTATION_MOVEIN | Orientation and move-in | JOURNEY |
| WARRANTY_SERVICE | Warranty and service | JOURNEY |
| COMMUNITY_AMENITY | Community and amenities | JOURNEY |
| LENDER_MORTGAGE | Lender and mortgage | JOURNEY |
| OVERALL_SATISFACTION | Overall satisfaction | SUMMARY |
| OTHER | Other | SUMMARY |

## Rules

- Exactly one `primary_theme_code` per classified comment
- Secondary themes comma-separated in `secondary_theme_codes`
- Unknown themes map to `OTHER`

## Examples

- First matching list in `classify_by_keywords` (v2): WARRANTY, CONSTRUCTION, DESIGN, SCHEDULE, CLOSING, ORIENTATION, LENDER, AMENITY, SALES
- Else `OVERALL_SATISFACTION`
- Additional matches go to `secondary_theme_codes`
