# Format a summariseOverlapCohort result into a visual table.

**\[experimental\]**

## Usage

``` r
tableCohortOverlap(
  result,
  uniqueCombinations = TRUE,
  type = "gt",
  header = c("variable_name"),
  groupColumn = c("cdm_name"),
  hide = c("variable_level", settingsColumns(result)),
  style = "default",
  .options = list()
)
```

## Arguments

- result:

  A summarised_result object.

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
# \donttest{
library(CohortCharacteristics)

cdm <- mockCohortCharacteristics()

overlap <- summariseCohortOverlap(cdm$cohort2)

tableCohortOverlap(overlap)
#> `result_id` is not present in result.


  


Cohort name reference
```

Cohort name comparator

Estimate name

Variable name

Only in reference cohort

In both cohorts

Only in comparator cohort

PP_MOCK

cohort_1

cohort_2

N (%)

3 (75.00%)

0 (0.00%)

1 (25.00%)

cohort_3

N (%)

3 (33.33%)

0 (0.00%)

6 (66.67%)

cohort_2

cohort_3

N (%)

1 (14.29%)

0 (0.00%)

6 (85.71%)

\# }
