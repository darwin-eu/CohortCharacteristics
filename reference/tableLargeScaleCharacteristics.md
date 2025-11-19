# Explore and compare the large scale characteristics of cohorts

Explore and compare the large scale characteristics of cohorts

## Usage

``` r
tableLargeScaleCharacteristics(
  result,
  compareBy = NULL,
  hide = c("type"),
  smdReference = NULL,
  type = "reactable"
)
```

## Arguments

- result:

  A summarised_result object.

- compareBy:

  A column to compare by it can be a choice between "cdm_name",
  "cohort_name", strata columns, "variable_level" (window) and "type".
  It can be left NULL for no comparison.

- hide:

  Columns to hide.

- smdReference:

  Level of reference for the Standardised Mean Differences (SMD), it has
  to be one of the values of `compareBy` column. If NULL no SMDs are
  displayed.

- type:

  Type of table to generate, it can be either `DT` or `reactable`.

## Value

A visual table.

## Examples

``` r
if (FALSE) { # \dontrun{
library(CohortCharacteristics)
library(omock)
library(CDMConnector)
library(dplyr, warn.conflicts = FALSE)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")

cdm <- generateConceptCohortSet(
  cdm = cdm,
  conceptSet = list(viral_pharyngitis = 4112343),
  name = "my_cohort"
)

result <- summariseLargeScaleCharacteristics(
  cohort = cdm$my_cohort,
  window = list(c(-Inf, -1), c(0, 0), c(1, Inf)),
  episodeInWindow = "drug_exposure"
)

tableLargeScaleCharacteristics(result)

tableLargeScaleCharacteristics(result,
                               compareBy = "variable_level")

tableLargeScaleCharacteristics(result,
                               compareBy = "variable_level",
                               smdReference = "-inf to -1")

cdmDisconnect(cdm)
} # }
```
