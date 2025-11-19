# Available columns to use in `header`, `groupColumn` and `hide` arguments in table functions.

Available columns to use in `header`, `groupColumn` and `hide` arguments
in table functions.

## Usage

``` r
availableTableColumns(result)
```

## Arguments

- result:

  A summarised_result object.

## Value

Character vector with the available columns.

## Examples

``` r
{
cdm <- mockCohortCharacteristics()

result <- summariseCharacteristics(cdm$cohort1)

availableTableColumns(result)

}
#> Warning: There are observation period end dates after the current date: 2025-11-19
#> ℹ The latest max observation period end date found is 2026-11-01
#> ℹ adding demographics columns
#> ℹ summarising data
#> ℹ summarising cohort cohort_1
#> ℹ summarising cohort cohort_2
#> ℹ summarising cohort cohort_3
#> ✔ summariseCharacteristics finished!
#> [1] "cdm_name"    "cohort_name" "table_name" 
```
