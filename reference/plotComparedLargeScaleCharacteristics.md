# create a ggplot from the output of summariseLargeScaleCharacteristics.

**\[experimental\]**

## Usage

``` r
plotComparedLargeScaleCharacteristics(
  result,
  colour,
  reference = NULL,
  facet = NULL,
  missings = 0,
  style = NULL
)
```

## Arguments

- result:

  A summarised_result object.

- colour:

  Columns to color by. See options with `availablePlotColumns(result)`.

- reference:

  A named character to set up the reference. It must be one of the
  levels of reference.

- facet:

  Columns to facet by. See options with `availablePlotColumns(result)`.
  Formula is also allowed to specify rows and columns.

- missings:

  Value to replace the missing value with. If NULL missing values will
  be eliminated.

- style:

  Visual theme to apply. Character, or `NULL`. If a character, this may
  be either the name of a built-in style (see `plotStyle()`), or a path
  to a `.yml` file that defines a custom style. If NULL, the function
  will use the explicit default style, unless a global style option is
  set (see `setGlobalPlotOptions()`), or a \_brand.yml file is present
  (in that order). Refer to the package vignette on styles to learn
  more.

## Value

A ggplot.

## Examples

``` r
if (FALSE) { # \dontrun{
library(CohortCharacteristics)
library(DrugUtilisation)
library(plotly, warn.conflicts = FALSE)

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
  plotComparedLargeScaleCharacteristics(
    colour = "variable_level",
    reference = "-365 to -1",
    missings = NULL
  ) |>
  ggplotly()

cdmDisconnect(cdm)
} # }
```
