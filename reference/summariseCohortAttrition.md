# Summarise attrition associated with cohorts in a cohort table

Summarise attrition associated with cohorts in a cohort table

## Usage

``` r
summariseCohortAttrition(cohort, cohortId = NULL)
```

## Arguments

- cohort:

  A cohort_table object.

- cohortId:

  A cohort definition id to restrict by. If NULL, all cohorts will be
  included.

## Value

A summary of the attrition for the cohorts in the cohort table.

## Examples

``` r
# \donttest{
library(CohortCharacteristics)
library(dplyr, warn.conflicts = FALSE)

cdm <- mockCohortCharacteristics()
#> Warning: There are observation period end dates after the current date: 2025-11-19
#> ℹ The latest max observation period end date found is 2028-07-10

summariseCohortAttrition(cohort = cdm$cohort1) |>
  glimpse()
#> Rows: 12
#> Columns: 13
#> $ result_id        <int> 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3
#> $ cdm_name         <chr> "PP_MOCK", "PP_MOCK", "PP_MOCK", "PP_MOCK", "PP_MOCK"…
#> $ group_name       <chr> "cohort_name", "cohort_name", "cohort_name", "cohort_…
#> $ group_level      <chr> "cohort_1", "cohort_1", "cohort_1", "cohort_1", "coho…
#> $ strata_name      <chr> "reason", "reason", "reason", "reason", "reason", "re…
#> $ strata_level     <chr> "Initial qualifying events", "Initial qualifying even…
#> $ variable_name    <chr> "number_records", "number_subjects", "excluded_record…
#> $ variable_level   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA
#> $ estimate_name    <chr> "count", "count", "count", "count", "count", "count",…
#> $ estimate_type    <chr> "integer", "integer", "integer", "integer", "integer"…
#> $ estimate_value   <chr> "4", "4", "0", "0", "2", "2", "0", "0", "4", "4", "0"…
#> $ additional_name  <chr> "reason_id", "reason_id", "reason_id", "reason_id", "…
#> $ additional_level <chr> "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1"…

# }
```
