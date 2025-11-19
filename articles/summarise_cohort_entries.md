# Summarise cohort entries

## Introduction

In this example we’re going to summarise the characteristics of
individuals with an ankle sprain, ankle fracture, forearm fracture, or a
hip fracture using the Eunomia synthetic data.

We’ll begin by creating our study cohorts.

``` r
library(omock)
library(CDMConnector)
library(dplyr, warn.conflicts = FALSE)
library(PatientProfiles)
library(CohortCharacteristics)
library(clock)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")

cdm <- generateConceptCohortSet(
  cdm = cdm,
  name = "injuries",
  conceptSet = list(
    "ankle_sprain" = 81151,
    "ankle_fracture" = 4059173,
    "forearm_fracture" = 4278672,
    "hip_fracture" = 4230399
  ),
  end = "event_end_date",
  limit = "all"
)
```

## Summarising cohort counts

We can first quickly summarise and present the overall counts of our
cohorts.

``` r
cohortCounts <- summariseCohortCount(cdm$injuries)
tableCohortCount(cohortCounts)
```

[TABLE]

Moreover, we can also easily stratify these counts. For example, here we
add age groups and then stratify our counts by t We can summarise the
overall counts of our cohorts.

``` r
cdm$injuries <- cdm$injuries |>
  addAge(
    ageGroup = list(c(0, 3), c(4, 17), c(18, Inf)),
    name = "injuries"
  )

cohortCounts <- summariseCohortCount(cdm[["injuries"]], strata = "age_group")
tableCohortCount(cohortCounts)
```

[TABLE]

We can also apply minimum cell count suppression to our cohort counts.
In this case we will obscure any counts below 10.

``` r
cohortCounts <- cohortCounts |>
  suppress(minCellCount = 10)
tableCohortCount(cohortCounts)
```

[TABLE]

## Summarising cohort attrition

Say we specify two inclusion criteria. First, we keep only cohort
entries after the year 2000. Second, we keep only cohort entries for
those aged 18 or older. We can easily create plots summarising our
cohort attrition.

``` r
cdm <- generateConceptCohortSet(
  cdm = cdm,
  name = "ankle_sprain",
  conceptSet = list("ankle_sprain" = 81151),
  end = "event_end_date",
  limit = "all"
)

cdm$ankle_sprain <- cdm$ankle_sprain |>
  filter(get_year(cohort_start_date) >= 2000) |>
  compute(temporary = FALSE, name = "ankle_sprain") |>
  recordCohortAttrition("Restrict to cohort_start_date >= 2000")

attritionSummary <- summariseCohortAttrition(cdm$ankle_sprain)

plotCohortAttrition(attritionSummary)
```

``` r
cdm$ankle_sprain <- cdm$ankle_sprain |>
  addAge() |>
  filter(age >= 18) |>
  compute(temporary = FALSE, name = "ankle_sprain") |>
  recordCohortAttrition("Restrict to age >= 18")

attritionSummary <- summariseCohortAttrition(cdm$ankle_sprain)

plotCohortAttrition(attritionSummary)
```

We could, of course, have applied these requirements the other way
around.

``` r
cdm <- generateConceptCohortSet(
  cdm = cdm,
  name = "ankle_sprain",
  conceptSet = list("ankle_sprain" = 81151),
  end = "event_end_date",
  limit = "all"
)

cdm$ankle_sprain <- cdm$ankle_sprain |>
  addAge() |>
  filter(age >= 18) |>
  compute(temporary = FALSE, name = "ankle_sprain") |>
  recordCohortAttrition("Restrict to age >= 18")

cdm$ankle_sprain <- cdm$ankle_sprain |>
  filter(get_year(cohort_start_date) >= 2000) |>
  compute(temporary = FALSE, name = "ankle_sprain") |>
  recordCohortAttrition("Restrict to cohort_start_date >= 2000")

attritionSummary <- summariseCohortAttrition(cdm$ankle_sprain)

plotCohortAttrition(attritionSummary)
```

As well as plotting cohort attrition, we can also create a table of our
results.

``` r
tableCohortAttrition(attritionSummary)
```

[TABLE]
