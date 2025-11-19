# Format a summarise_characteristics object into a visual table.

**\[experimental\]**

## Usage

``` r
tableCohortCount(
  result,
  type = "gt",
  header = "cohort_name",
  groupColumn = character(),
  hide = c("variable_level", settingsColumns(result)),
  style = "default",
  .options = list()
)
```

## Arguments

- result:

  A summarised_result object.

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
# \donttest{
library(CohortCharacteristics)

cdm <- mockCohortCharacteristics()

result <- summariseCohortCount(cdm$cohort1)
#> ℹ summarising data
#> ℹ summarising cohort cohort_1
#> ℹ summarising cohort cohort_2
#> ℹ summarising cohort cohort_3
#> ✔ summariseCharacteristics finished!

tableCohortCount(result)


  


CDM name
```

Variable name

Estimate name

Cohort name

cohort_1

cohort_2

cohort_3

PP_MOCK

Number records

N

3

2

5

Number subjects

N

3

2

5

\# }
