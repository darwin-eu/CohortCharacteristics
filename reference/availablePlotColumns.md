# Available columns to use in `facet` and `colour` arguments in plot functions.

Available columns to use in `facet` and `colour` arguments in plot
functions.

## Usage

``` r
availablePlotColumns(result)
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

availablePlotColumns(result)

}
#> ℹ adding demographics columns
#> ℹ summarising data
#> ℹ summarising cohort cohort_1
#> ℹ summarising cohort cohort_2
#> ℹ summarising cohort cohort_3
#> ✔ summariseCharacteristics finished!
#>  [1] "cdm_name"    "cohort_name" "table_name"  "count"       "min"        
#>  [6] "q25"         "median"      "q75"         "max"         "mean"       
#> [11] "sd"          "percentage" 
```
