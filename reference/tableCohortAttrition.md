# Create a visual table from the output of summariseCohortAttrition.

**\[experimental\]**

## Usage

``` r
tableCohortAttrition(
  result,
  type = NULL,
  header = "variable_name",
  groupColumn = c("cdm_name", "cohort_name"),
  hide = c("variable_level", "reason_id", "estimate_name", settingsColumns(result)),
  style = NULL,
  .options = list()
)
```

## Arguments

- result:

  A summarised_result object.

- type:

  Character string specifying the desired output table format. See
  [`visOmopResults::tableType()`](https://darwin-eu.github.io/visOmopResults/reference/tableType.html)
  for supported table types. If type = `NULL`, global options (set via
  [`visOmopResults::setGlobalTableOptions()`](https://darwin-eu.github.io/visOmopResults/reference/setGlobalTableOptions.html))
  will be used if available; otherwise, a default 'gt' table is created.

- header:

  Columns to use as header. See options with
  `availableTableColumns(result)`.

- groupColumn:

  Columns to group by. See options with `availableTableColumns(result)`.

- hide:

  Columns to hide from the visualisation. See options with
  `availableTableColumns(result)`.

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

1

1

0

0

PP_MOCK; cohort_2

Initial qualifying events

3

3

0

0

PP_MOCK; cohort_3

Initial qualifying events

6

6

0

0

\# }
