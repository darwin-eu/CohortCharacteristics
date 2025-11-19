# Create a visual table from the output of summariseCohortAttrition.

**\[experimental\]**

## Usage

``` r
tableCohortAttrition(
  result,
  type = "gt",
  header = "variable_name",
  groupColumn = c("cdm_name", "cohort_name"),
  hide = c("variable_level", "reason_id", "estimate_name", settingsColumns(result)),
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

result <- summariseCohortAttrition(cdm$cohort2)

tableCohortAttrition(result)


  


Reason
```

Variable name

number_records

number_subjects

excluded_records

excluded_subjects

PP_MOCK; cohort_1

Initial qualifying events

3

3

0

0

PP_MOCK; cohort_2

Initial qualifying events

6

6

0

0

PP_MOCK; cohort_3

Initial qualifying events

1

1

0

0

\# }
