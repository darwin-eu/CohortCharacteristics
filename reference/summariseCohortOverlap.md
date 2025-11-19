# Summarise overlap between cohorts in a cohort table

Summarise overlap between cohorts in a cohort table

## Usage

``` r
summariseCohortOverlap(
  cohort,
  cohortId = NULL,
  strata = list(),
  overlapBy = "subject_id"
)
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

- overlapBy:

  Columns in cohort to use as record identifiers.

## Value

A summary of overlap between cohorts in the cohort table.

## Examples

``` r
# \donttest{
library(CohortCharacteristics)
library(dplyr, warn.conflicts = FALSE)

cdm <- mockCohortCharacteristics()

summariseCohortOverlap(cdm$cohort2) |>
  glimpse()
#> Rows: 36
#> Columns: 13
#> $ result_id        <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
#> $ cdm_name         <chr> "PP_MOCK", "PP_MOCK", "PP_MOCK", "PP_MOCK", "PP_MOCK"…
#> $ group_name       <chr> "cohort_name_reference &&& cohort_name_comparator", "…
#> $ group_level      <chr> "cohort_1 &&& cohort_2", "cohort_1 &&& cohort_2", "co…
#> $ strata_name      <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ strata_level     <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ variable_name    <chr> "Only in reference cohort", "In both cohorts", "Only …
#> $ variable_level   <chr> "Subjects", "Subjects", "Subjects", "Subjects", "Subj…
#> $ estimate_name    <chr> "count", "count", "count", "count", "count", "count",…
#> $ estimate_type    <chr> "integer", "integer", "integer", "integer", "integer"…
#> $ estimate_value   <chr> "4", "0", "3", "4", "0", "3", "3", "0", "4", "3", "0"…
#> $ additional_name  <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ additional_level <chr> "overall", "overall", "overall", "overall", "overall"…

# }
```
