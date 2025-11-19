# Create a visual table from `<summarised_result>` object from `summariseCohortCodelist()`

**\[experimental\]**

## Usage

``` r
tableCohortCodelist(result, type = "reactable")
```

## Arguments

- result:

  A summarised_result object.

- type:

  Type of table. Supported types: "gt", "flextable", "tibble",
  "datatable", "reactable".

## Value

A visual table with the results.

## Examples

``` r
# \donttest{
library(CohortCharacteristics)
library(omock)
library(dplyr, warn.conflicts = FALSE)
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

tableCohortCodelist(result)

{"x":{"tag":{"name":"Reactable","attribs":{"data":{"cdm_name":["GiBleed"],"cohort_name":["pharyngitis"],"codelist_name":["pharyngitis"],"codelist_type":["index event"],"concept_name":["Acute viral pharyngitis"],"concept_id":[4112343]},"columns":[{"id":"cdm_name","name":"cdm_name","type":"character"},{"id":"cohort_name","name":"cohort_name","type":"character"},{"id":"codelist_name","name":"codelist_name","type":"character"},{"id":"codelist_type","name":"codelist_type","type":"character"},{"id":"concept_name","name":"concept_name","type":"character"},{"id":"concept_id","name":"concept_id","type":"numeric"}],"filterable":true,"dataKey":"c175f9686a710e7089caa511e1765878"},"children":[]},"class":"reactR_markup"},"evals":[],"jsHooks":[]}# }
```
