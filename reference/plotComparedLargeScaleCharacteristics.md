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
  style = "default"
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

  Named list that specifies how to style the different parts of the
  table generated. It can either be a pre-defined style ("default" or
  "darwin" - the latter just for gt and flextable), NULL to get the
  table default style, or custom. Keep in mind that styling code is
  different for all table styles. To see the different styles see
  [`visOmopResults::tableStyle()`](https://darwin-eu.github.io/visOmopResults/reference/tableStyle.html).

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
