# Format a summariseCohortTiming result into a visual table.

**\[experimental\]**

## Usage

``` r
tableCohortTiming(
  result,
  timeScale = "days",
  uniqueCombinations = TRUE,
  type = "gt",
  header = strataColumns(result),
  groupColumn = c("cdm_name"),
  hide = c("variable_level", settingsColumns(result)),
  style = "default",
  .options = list()
)
```

## Arguments

- result:

  A summarised_result object.

- timeScale:

  Time scale to show, it can be "days" or "years".

- uniqueCombinations:

  Whether to restrict to unique reference and comparator comparisons.

- type:

  Type of table. Check supported types with
  [`visOmopResults::tableType()`](https://darwin-eu.github.io/visOmopResults/reference/tableType.html).

- header:

  Columns to use as header. See options with
  `availableTableColumns(result)`.

- groupColumn:

  Columns to group by. See options with `availableTableColumns(result)`.

- hide:

  Columns to hide from the visualisation. See options with
  `availableTableColumns(result)`.

- style:

  Named list that specifies how to style the different parts of the
  table generated. It can either be a pre-defined style ("default" or
  "darwin" - the latter just for gt and flextable), NULL to get the
  table default style, or custom. Keep in mind that styling code is
  different for all table styles. To see the different styles see
  [`visOmopResults::tableStyle()`](https://darwin-eu.github.io/visOmopResults/reference/tableStyle.html).

- .options:

  A named list with additional formatting options.
  [`visOmopResults::tableOptions()`](https://darwin-eu.github.io/visOmopResults/reference/tableOptions.html)
  shows allowed arguments and their default values.

## Value

A formatted table.

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

tableCohortTiming(timings, timeScale = "years")

cdmDisconnect(cdm)
} # }
```
