# Summarise characteristics of cohorts in a cohort table

Summarise characteristics of cohorts in a cohort table

## Usage

``` r
summariseCharacteristics(
  cohort,
  cohortId = NULL,
  strata = list(),
  counts = TRUE,
  demographics = TRUE,
  ageGroup = NULL,
  tableIntersectFlag = list(),
  tableIntersectCount = list(),
  tableIntersectDate = list(),
  tableIntersectDays = list(),
  cohortIntersectFlag = list(),
  cohortIntersectCount = list(),
  cohortIntersectDate = list(),
  cohortIntersectDays = list(),
  conceptIntersectFlag = list(),
  conceptIntersectCount = list(),
  conceptIntersectDate = list(),
  conceptIntersectDays = list(),
  otherVariables = character(),
  estimates = list(),
  weights = NULL
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

- counts:

  TRUE or FALSE. If TRUE, record and person counts will be produced.

- demographics:

  TRUE or FALSE. If TRUE, patient demographics (cohort start date,
  cohort end date, age, sex, prior observation, and future observation
  will be summarised).

- ageGroup:

  A list of age groups to stratify results by.

- tableIntersectFlag:

  A list of arguments that uses PatientProfiles::addTableIntersectFlag()
  to add variables to summarise.

- tableIntersectCount:

  A list of arguments that uses
  PatientProfiles::addTableIntersectCount() to add variables to
  summarise.

- tableIntersectDate:

  A list of arguments that uses PatientProfiles::addTableIntersectDate()
  to add variables to summarise.

- tableIntersectDays:

  A list of arguments that uses PatientProfiles::addTableIntersectDays()
  to add variables to summarise.

- cohortIntersectFlag:

  A list of arguments that uses
  PatientProfiles::addCohortIntersectFlag() to add variables to
  summarise.

- cohortIntersectCount:

  A list of arguments that uses
  PatientProfiles::addCohortIntersectCount() to add variables to
  summarise.

- cohortIntersectDate:

  A list of arguments that uses
  PatientProfiles::addCohortIntersectDate() to add variables to
  summarise.

- cohortIntersectDays:

  A list of arguments that uses
  PatientProfiles::addCohortIntersectDays() to add variables to
  summarise.

- conceptIntersectFlag:

  A list of arguments that uses
  PatientProfiles::addConceptIntersectFlag() to add variables to
  summarise.

- conceptIntersectCount:

  A list of arguments that uses
  PatientProfiles::addConceptIntersectCount() to add variables to
  summarise.

- conceptIntersectDate:

  A list of arguments that uses
  PatientProfiles::addConceptIntersectDate() to add variables to
  summarise.

- conceptIntersectDays:

  A list of arguments that uses
  PatientProfiles::addConceptIntersectDays() to add variables to
  summarise.

- otherVariables:

  Other variables contained in cohort that you want to be summarised.

- estimates:

  To modify the default estimates for a variable. By default: 'min',
  'q25', 'median', 'q75', 'max' for "date", for "numeric" and "integer"
  variables ("numeric" and "integer" also use 'mean' and 'sd'
  estimates). 'count' and 'percentage' for "categorical" and "binary".
  You have to provide them as a list:
  `list(age = c("median", "density"))`. You can also use 'date',
  'numeric', 'integer', 'binary', 'categorical', 'demographics',
  'intersect', 'other', 'table_intersect_count', ... as valid labels,
  see available estimates using
  [`PatientProfiles::availableEstimates()`](https://darwin-eu.github.io/PatientProfiles/reference/availableEstimates.html)

- weights:

  Column in cohort that points to weights of each individual.

## Value

A summary of the characteristics of the cohorts in the cohort table.

## Examples

``` r
# \donttest{
library(dplyr, warn.conflicts = FALSE)
library(CohortCharacteristics)
library(PatientProfiles)

cdm <- mockCohortCharacteristics()

cdm$cohort1 |>
  addSex() |>
  addAge(
    ageGroup = list(c(0, 40), c(41, 150))
  ) |>
  summariseCharacteristics(
    strata = list("sex", "age_group"),
    cohortIntersectFlag = list(
      "Cohort 2 Flag" = list(
        targetCohortTable = "cohort2", window = c(-365, 0)
      )
    ),
    cohortIntersectCount = list(
      "Cohort 2 Count" = list(
        targetCohortTable = "cohort2", window = c(-365, 0)
      )
    )
  ) |>
  glimpse()
#> ℹ adding demographics columns
#> ℹ adding cohortIntersectFlag 1/1
#> window names casted to snake_case:
#> • `-365 to 0` -> `365_to_0`
#> ℹ adding cohortIntersectCount 1/1
#> window names casted to snake_case:
#> • `-365 to 0` -> `365_to_0`
#> ℹ summarising data
#> ℹ summarising cohort cohort_1
#> ℹ summarising cohort cohort_2
#> ℹ summarising cohort cohort_3
#> ✔ summariseCharacteristics finished!
#> Rows: 920
#> Columns: 13
#> $ result_id        <int> 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,…
#> $ cdm_name         <chr> "PP_MOCK", "PP_MOCK", "PP_MOCK", "PP_MOCK", "PP_MOCK"…
#> $ group_name       <chr> "cohort_name", "cohort_name", "cohort_name", "cohort_…
#> $ group_level      <chr> "cohort_1", "cohort_1", "cohort_1", "cohort_1", "coho…
#> $ strata_name      <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ strata_level     <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ variable_name    <chr> "Number records", "Number subjects", "Cohort start da…
#> $ variable_level   <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, N…
#> $ estimate_name    <chr> "count", "count", "min", "q25", "median", "q75", "max…
#> $ estimate_type    <chr> "integer", "integer", "date", "date", "date", "date",…
#> $ estimate_value   <chr> "5", "5", "1930-02-09", "1966-02-09", "1971-03-07", "…
#> $ additional_name  <chr> "overall", "overall", "overall", "overall", "overall"…
#> $ additional_level <chr> "overall", "overall", "overall", "overall", "overall"…

# }
```
