# create a ggplot from the output of summariseLargeScaleCharacteristics.

**\[experimental\]**

## Usage

``` r
plotLargeScaleCharacteristics(
  result,
  facet = c("cdm_name", "cohort_name"),
  colour = "variable_level",
  style = NULL
)
```

## Arguments

- result:

  A summarised_result object.

- facet:

  Columns to facet by. See options with `availablePlotColumns(result)`.
  Formula is also allowed to specify rows and columns.

- colour:

  Columns to color by. See options with `availablePlotColumns(result)`.

- style:

  Visual theme to apply. Character, or `NULL`. If a character, this may
  be either the name of a built-in style (see `plotStyle()`), or a path
  to a `.yml` file that defines a custom style. If NULL, the function
  will use the explicit default style, unless a global style option is
  set (see `setGlobalPlotOptions()`), or a \_brand.yml file is present
  (in that order). Refer to the package vignette on styles to learn
  more.

## Value

A ggplot2 object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(CohortCharacteristics)
library(omock)
library(DrugUtilisation)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")

cdm <- generateIngredientCohortSet(
  cdm = cdm, name = "my_cohort", ingredient = "acetaminophen"
)

resultsLsc <- cdm$my_cohort |>
  summariseLargeScaleCharacteristics(
    window = list(c(-365, -1), c(1, 365)),
    eventInWindow = "condition_occurrence"
  )

resultsLsc |>
  plotLargeScaleCharacteristics(
    facet = c("cdm_name", "cohort_name"),
    colour = "variable_level"
  )

cdmDisconnect(cdm)
} # }
```
