# Visualise the top concepts per each cdm name, cohort, statification and window.

Visualise the top concepts per each cdm name, cohort, statification and
window.

## Usage

``` r
tableTopLargeScaleCharacteristics(
  result,
  topConcepts = 10,
  type = NULL,
  style = NULL
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

  Defines the visual formatting of the table. This argument can be
  provided in one of the following ways:

  1.  **Pre-defined style**: Use the name of a built-in style (e.g.,
      "darwin"). See
      [`visOmopResults::tableStyle()`](https://darwin-eu.github.io/visOmopResults/reference/tableStyle.html)
      for available options.

  2.  **YAML file path**: Provide the path to an existing .yml file
      defining a new style.

  3.  **List of custome R code**: Supply a block of custom R code or a
      named list describing styles for each table section. This code
      must be specific to the selected table type.

  If style = `NULL`, the function will use global options (see
  [`visOmopResults::setGlobalTableOptions()`](https://darwin-eu.github.io/visOmopResults/reference/setGlobalTableOptions.html))
  or an existing `_brand.yml` file (if found); otherwise, the default
  style is applied. For more details, see the *Styles* vignette in
  **visOmopResults** website.

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
