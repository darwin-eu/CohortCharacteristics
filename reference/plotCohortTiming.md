# Plot summariseCohortTiming results.

**\[experimental\]**

## Usage

``` r
plotCohortTiming(
  result,
  plotType = "boxplot",
  timeScale = "days",
  uniqueCombinations = TRUE,
  facet = c("cdm_name", "cohort_name_reference"),
  colour = c("cohort_name_comparator"),
  style = NULL
)
```

## Arguments

- result:

  A summarised_result object.

- plotType:

  Type of desired formatted table, possibilities are "boxplot" and
  "densityplot".

- timeScale:

  Time scale to show, it can be "days" or "years".

- uniqueCombinations:

  Whether to restrict to unique reference and comparator comparisons.

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

A ggplot.

## Examples

``` r
if (FALSE) { # \dontrun{
library(CohortCharacteristics)
library(omock)
library(DrugUtilisation)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")

cdm <- generateIngredientCohortSet(
  cdm = cdm,
  name = "my_cohort",
  ingredient = c("acetaminophen", "morphine", "warfarin")
)

timings <- summariseCohortTiming(cdm$my_cohort)

plotCohortTiming(
  timings,
  timeScale = "years",
  uniqueCombinations = FALSE,
  facet = c("cdm_name", "cohort_name_reference"),
  colour = c("cohort_name_comparator")
)

plotCohortTiming(
  timings,
  plotType = "densityplot",
  timeScale = "years",
  uniqueCombinations = FALSE,
  facet = c("cdm_name", "cohort_name_reference"),
  colour = c("cohort_name_comparator")
)

cdmDisconnect(cdm = cdm)
} # }
```
