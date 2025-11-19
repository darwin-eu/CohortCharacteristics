# Format a summarise_characteristics object into a visual table.

**\[experimental\]**

## Usage

``` r
tableCharacteristics(
  result,
  type = "gt",
  header = c("cdm_name", "cohort_name"),
  groupColumn = character(),
  hide = c(additionalColumns(result), settingsColumns(result)),
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

3

2

5

Number subjects

–

N

3

2

5

Cohort start date

–

Median \[Q25 - Q75\]

1939-04-04 \[1931-03-07 - 1962-11-03\]

1956-05-23 \[1952-07-16 - 1960-03-30\]

1970-07-27 \[1928-11-20 - 1970-12-30\]

Range

1923-02-07 to 1986-06-03

1948-09-07 to 1964-02-06

1918-02-19 to 1986-06-26

Cohort end date

–

Median \[Q25 - Q75\]

1943-03-31 \[1934-08-30 - 1965-04-29\]

1957-10-13 \[1953-11-08 - 1961-09-17\]

1976-02-14 \[1944-02-02 - 1995-01-09\]

Range

1926-01-28 to 1987-05-28

1949-12-05 to 1965-08-21

1920-06-10 to 2002-07-14

Age

–

Median \[Q25 - Q75\]

16 \[16 - 18\]

15 \[9 - 21\]

16 \[5 - 22\]

Mean (SD)

16.67 (2.08)

15.00 (16.97)

13.60 (10.78)

Range

15 to 19

3 to 27

0 to 25

Sex

Female

N (%)

2 (66.67%)

1 (50.00%)

2 (40.00%)

Male

N (%)

1 (33.33%)

1 (50.00%)

3 (60.00%)

Prior observation

–

Median \[Q25 - Q75\]

5,937 \[5,726 - 6,515\]

5,621 \[3,483 - 7,759\]

6,207 \[1,875 - 8,359\]

Mean (SD)

6,182.00 (816.55)

5,621.00 (6,047.18)

5,191.00 (3,995.19)

Range

5,516 to 7,093

1,345 to 9,897

207 to 9,307

Future observation

–

Median \[Q25 - Q75\]

6,601 \[6,402 - 7,606\]

1,005 \[990 - 1,020\]

3,803 \[2,547 - 6,393\]

Mean (SD)

7,138.67 (1,291.37)

1,005.00 (43.84)

5,330.00 (4,025.61)

Range

6,203 to 8,612

974 to 1,036

2,037 to 11,870

Days in cohort

–

Median \[Q25 - Q75\]

1,087 \[724 - 1,272\]

509 \[482 - 536\]

3,120 \[1,873 - 5,553\]

Mean (SD)

968.33 (558.54)

509.00 (76.37)

4,613.00 (4,322.01)

Range

360 to 1,458

455 to 563

843 to 11,676

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
