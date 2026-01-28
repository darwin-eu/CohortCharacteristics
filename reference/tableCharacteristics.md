# Format a summarise_characteristics object into a visual table.

**\[experimental\]**

## Usage

``` r
tableCharacteristics(
  result,
  type = NULL,
  header = c("cdm_name", "cohort_name"),
  groupColumn = character(),
  hide = c(additionalColumns(result), settingsColumns(result)),
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
#> Warning: There are observation period end dates after the current date: 2026-01-28
#> ℹ The latest max observation period end date found is 2030-07-06

result <- summariseCharacteristics(cdm$cohort1)
#> ℹ adding demographics columns
#> ℹ summarising data
#> ℹ summarising cohort cohort_1
#> ℹ summarising cohort cohort_2
#> ℹ summarising cohort cohort_3
#> ✔ summariseCharacteristics finished!

tableCharacteristics(result)


  

```

CDM name

PP_MOCK

Variable name

Variable level

Estimate name

Cohort name

cohort_1

cohort_2

cohort_3

Number records

–

N

4

3

3

Number subjects

–

N

4

3

3

Cohort start date

–

Median \[Q25 - Q75\]

1956-03-13 \[1934-06-15 - 1983-10-06\]

1980-10-23 \[1945-11-16 - 1985-12-18\]

1932-12-15 \[1924-12-14 - 1937-04-05\]

Range

1932-01-19 to 2003-08-17

1910-12-10 to 1991-02-12

1916-12-12 to 1941-07-25

Cohort end date

–

Median \[Q25 - Q75\]

1960-05-09 \[1935-12-13 - 1992-12-27\]

1985-09-18 \[1949-02-26 - 1988-06-17\]

1934-12-20 \[1926-07-11 - 1940-10-02\]

Range

1935-02-09 to 2018-07-05

1912-08-07 to 1991-03-16

1918-01-29 to 1946-07-16

Age

–

Median \[Q25 - Q75\]

12 \[8 - 17\]

23 \[13 - 30\]

11 \[8 - 16\]

Mean (SD)

12.75 (10.69)

21.33 (17.56)

12.33 (9.07)

Range

0 to 26

3 to 38

4 to 22

Sex

Female

N (%)

2 (50.00%)

1 (33.33%)

3 (100.00%)

Male

N (%)

2 (50.00%)

2 (66.67%)

–

Prior observation

–

Median \[Q25 - Q75\]

4,621 \[3,096 - 6,279\]

8,696 \[5,068 - 11,308\]

4,363 \[3,014 - 6,374\]

Mean (SD)

4,754.00 (3,974.25)

8,018.67 (6,268.51)

4,804.33 (3,380.67)

Range

50 to 9,724

1,439 to 13,921

1,666 to 8,384

Future observation

–

Median \[Q25 - Q75\]

6,548 \[2,965 - 9,649\]

2,478 \[1,309 - 3,920\]

2,078 \[1,409 - 2,210\]

Mean (SD)

6,065.25 (4,296.56)

2,659.67 (2,615.24)

1,720.00 (858.91)

Range

1,344 to 9,820

140 to 5,361

740 to 2,342

Days in cohort

–

Median \[Q25 - Q75\]

1,900 \[928 - 3,372\]

607 \[320 - 1,200\]

736 \[575 - 1,277\]

Mean (SD)

2,398.50 (2,245.36)

810.67 (897.01)

989.33 (735.48)

Range

356 to 5,437

33 to 1,792

414 to 1,818

Days to next record

–

Median \[Q25 - Q75\]

–

–

–

Mean (SD)

–

–

–

Range

–

–

–

\# }
