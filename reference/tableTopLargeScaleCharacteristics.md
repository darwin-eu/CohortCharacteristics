# Visualise the top concepts per each cdm name, cohort, statification and window.

Visualise the top concepts per each cdm name, cohort, statification and
window.

## Usage

``` r
tableTopLargeScaleCharacteristics(
  result,
  topConcepts = 10,
  type = "gt",
  style = "default"
)
```

## Arguments

- result:

  A summarised_result object.

- topConcepts:

  Number of concepts to restrict the table.

- type:

  Type of table, it can be any of the supported
  [`visOmopResults::tableType()`](https://darwin-eu.github.io/visOmopResults/reference/tableType.html)
  formats.

- style:

  Named list that specifies how to style the different parts of the
  table generated. It can either be a pre-defined style ("default" or
  "darwin" - the latter just for gt and flextable), NULL to get the
  table default style, or custom. Keep in mind that styling code is
  different for all table styles. To see the different styles see
  [`visOmopResults::tableStyle()`](https://darwin-eu.github.io/visOmopResults/reference/tableStyle.html).

## Value

A formated table.

## Examples

``` r
if (FALSE) { # \dontrun{
library(CohortCharacteristics)
library(omock)
libarry(CDMConnector)
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

tableTopLargeScaleCharacteristics(result)

cdmDisconnect(cdm)
} # }
```
