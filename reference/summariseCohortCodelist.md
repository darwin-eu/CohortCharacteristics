# Summarise the cohort codelist attribute

**\[experimental\]**

## Usage

``` r
summariseCohortCodelist(cohort, cohortId = NULL)
```

## Arguments

- cohort:

  A cohort_table object.

- cohortId:

  A cohort definition id to restrict by. If NULL, all cohorts will be
  included.

## Value

A summarised_result object with the exported cohort codelist
information.

## Examples

``` r
# \donttest{
library(CohortCharacteristics)
library(dplyr, warn.conflicts = FALSE)
library(omock)
library(CDMConnector)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#> ℹ Reading GiBleed tables.
#> ℹ Adding drug_strength table.
#> ℹ Creating local <cdm_reference> object.
#> ℹ Inserting <cdm_reference> into duckdb.

cdm <- generateConceptCohortSet(cdm = cdm,
                                conceptSet = list(pharyngitis = 4112343L),
                                name = "my_cohort")

result <- summariseCohortCodelist(cdm$my_cohort)

glimpse(result)
#> Rows: 1
#> Columns: 13
#> $ result_id        <int> 1
#> $ cdm_name         <chr> "GiBleed"
#> $ group_name       <chr> "cohort_name"
#> $ group_level      <chr> "pharyngitis"
#> $ strata_name      <chr> "codelist_name &&& codelist_type"
#> $ strata_level     <chr> "pharyngitis &&& index event"
#> $ variable_name    <chr> "overall"
#> $ variable_level   <chr> "overall"
#> $ estimate_name    <chr> "concept_id"
#> $ estimate_type    <chr> "integer"
#> $ estimate_value   <chr> "4112343"
#> $ additional_name  <chr> "concept_name"
#> $ additional_level <chr> "Acute viral pharyngitis"

tidy(result)
#> # A tibble: 1 × 8
#>   cdm_name cohort_name codelist_name codelist_type variable_name variable_level
#>   <chr>    <chr>       <chr>         <chr>         <chr>         <chr>         
#> 1 GiBleed  pharyngitis pharyngitis   index event   overall       overall       
#> # ℹ 2 more variables: concept_name <chr>, concept_id <int>
# }
```
