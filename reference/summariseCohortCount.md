# Summarise counts for cohorts in a cohort table

Summarise counts for cohorts in a cohort table

## Usage

``` r
summariseCohortCount(cohort, cohortId = NULL, strata = list())
```

## Arguments

- cohort:

  A cohort_table object.

- cohortId:

  A cohort definition id to restrict by. If NULL, all cohorts will be
  included.

- strata:

  A list of variables to stratify results. These variables must have
  been added as additional columns in the cohort table.

## Value

A summary of counts of the cohorts in the cohort table.

## Examples

``` r
# \donttest{
library(CohortCharacteristics)
library(dplyr, warn.conflicts = FALSE)

cdm <- mockCohortCharacteristics()

summariseCohortCount(cohort = cdm$cohort1) |>
  glimpse()
#> ℹ summarising data
#> ℹ summarising cohort cohort_1
#> ℹ summarising cohort cohort_2
#> ℹ summarising cohort cohort_3
#> ✔ summariseCharacteristics finished!
#> Rows: 6
#> Columns: 13
#> $ result_id        <int> 1, 1, 1, 1, 1, 1
#> $ cdm_name         <chr> "PP_MOCK", "PP_MOCK", "PP_MOCK", "PP_MOCK", "PP_MOCK"…
#> $ group_name       <chr> "cohort_name", "cohort_name", "cohort_name", "cohort_…
#> $ group_level      <chr> "cohort_1", "cohort_1", "cohort_2", "cohort_2", "coho…
#> $ strata_name      <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ strata_level     <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ variable_name    <chr> "Number records", "Number subjects", "Number records"…
#> $ variable_level   <chr> NA, NA, NA, NA, NA, NA
#> $ estimate_name    <chr> "count", "count", "count", "count", "count", "count"
#> $ estimate_type    <chr> "integer", "integer", "integer", "integer", "integer"…
#> $ estimate_value   <chr> "4", "4", "2", "2", "4", "4"
#> $ additional_name  <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ additional_level <chr> "overall", "overall", "overall", "overall", "overall"…

# }
```
