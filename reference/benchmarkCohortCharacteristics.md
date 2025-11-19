# Benchmark the main functions of CohortCharacteristics package.

Benchmark the main functions of CohortCharacteristics package.

## Usage

``` r
benchmarkCohortCharacteristics(
  cohort,
  analysis = c("count", "attrition", "characteristics", "overlap", "timing",
    "large scale characteristics")
)
```

## Arguments

- cohort:

  A cohort_table from a cdm_reference.

- analysis:

  Set of analysis to perform, must be a subset of: "count", "attrition",
  "characteristics", "overlap", "timing" and "large scale
  characteristics".

## Value

A summarised_result object.

## Examples

``` r
if (FALSE) { # \dontrun{
library(CohortCharacteristics)
library(omock)
library(CDMConnector)

cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")

cdm <- generateConceptCohortSet(
  cdm = cdm,
  conceptSet = list(sinusitis = 40481087, pharyngitis = 4112343),
  name = "my_cohort"
)

benchmarkCohortCharacteristics(cdm$my_cohort)

} # }
```
