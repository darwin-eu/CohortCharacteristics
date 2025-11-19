# Summarise timing between entries into cohorts in a cohort table

Summarise timing between entries into cohorts in a cohort table

## Usage

``` r
summariseCohortTiming(
  cohort,
  cohortId = NULL,
  strata = list(),
  restrictToFirstEntry = TRUE,
  estimates = c("min", "q25", "median", "q75", "max", "density"),
  density = lifecycle::deprecated()
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

- restrictToFirstEntry:

  If TRUE only an individual's first entry per cohort will be
  considered. If FALSE all entries per individual will be considered.

- estimates:

  Summary statistics to use when summarising timing.

- density:

  deprecated.

## Value

A summary of timing between entries into cohorts in the cohort table.

## Examples

``` r
# \donttest{
library(CohortCharacteristics)
library(dplyr, warn.conflicts = FALSE)

cdm <- mockCohortCharacteristics(numberIndividuals = 100)
#> Warning: There are observation period end dates after the current date: 2025-11-19
#> ℹ The latest max observation period end date found is 2026-10-21

summariseCohortTiming(cdm$cohort2) |>
  glimpse()
#> Rows: 0
#> Columns: 13
#> $ result_id        <int> 
#> $ cdm_name         <chr> 
#> $ group_name       <chr> 
#> $ group_level      <chr> 
#> $ strata_name      <chr> 
#> $ strata_level     <chr> 
#> $ variable_name    <chr> 
#> $ variable_level   <chr> 
#> $ estimate_name    <chr> 
#> $ estimate_type    <chr> 
#> $ estimate_value   <chr> 
#> $ additional_name  <chr> 
#> $ additional_level <chr> 

# }
```
