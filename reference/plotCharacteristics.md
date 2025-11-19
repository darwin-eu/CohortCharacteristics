# Create a ggplot from the output of summariseCharacteristics.

**\[experimental\]**

## Usage

``` r
plotCharacteristics(
  result,
  plotType = "barplot",
  facet = NULL,
  colour = NULL,
  style = "default",
  plotStyle = lifecycle::deprecated()
)
```

## Arguments

- result:

  A summarised_result object.

- plotType:

  Either `barplot`, `scatterplot` or `boxplot`. If `barplot` or
  `scatterplot` subset to just one estimate.

- facet:

  Columns to facet by. See options with `availablePlotColumns(result)`.
  Formula is also allowed to specify rows and columns.

- colour:

  Columns to color by. See options with `availablePlotColumns(result)`.

- style:

  Named list that specifies how to style the different parts of the
  table generated. It can either be a pre-defined style ("default" or
  "darwin" - the latter just for gt and flextable), NULL to get the
  table default style, or custom. Keep in mind that styling code is
  different for all table styles. To see the different styles see
  [`visOmopResults::tableStyle()`](https://darwin-eu.github.io/visOmopResults/reference/tableStyle.html).

- plotStyle:

  deprecated.

## Value

A ggplot.

## Examples

``` r
# \donttest{
library(CohortCharacteristics)
library(dplyr, warn.conflicts = FALSE)

cdm <- mockCohortCharacteristics()

results <- summariseCharacteristics(
  cohort = cdm$cohort1,
  ageGroup = list(c(0, 19), c(20, 39), c(40, 59), c(60, 79), c(80, 150)),
  tableIntersectCount = list(
    tableName = "visit_occurrence", window = c(-365, -1)
  ),
  cohortIntersectFlag = list(
    targetCohortTable = "cohort2", window = c(-365, -1)
  )
)
#> ℹ adding demographics columns
#> ℹ adding tableIntersectCount 1/1
#> window names casted to snake_case:
#> • `-365 to -1` -> `365_to_1`
#> ℹ adding cohortIntersectFlag 1/1
#> window names casted to snake_case:
#> • `-365 to -1` -> `365_to_1`
#> ℹ summarising data
#> ℹ summarising cohort cohort_1
#> ℹ summarising cohort cohort_2
#> ℹ summarising cohort cohort_3
#> ✔ summariseCharacteristics finished!

results |>
  filter(
    variable_name == "Cohort2 flag -365 to -1", estimate_name == "percentage"
  ) |>
  plotCharacteristics(
    plotType = "barplot",
    colour = "variable_level",
    facet = c("cdm_name", "cohort_name")
  )


results |>
  filter(variable_name == "Age", estimate_name == "mean") |>
  plotCharacteristics(
    plotType = "scatterplot",
    facet = "cdm_name"
  )


results |>
  filter(variable_name == "Age", group_level == "cohort_1") |>
  plotCharacteristics(
    plotType = "boxplot",
    facet = "cdm_name",
    colour = "cohort_name"
  )
#> Ignoring unknown labels:
#> • fill : "Cohort name"
#> Warning: `label` cannot be a <ggplot2::element_blank> object.


# }
```
