# create a ggplot from the output of summariseLargeScaleCharacteristics.

**\[experimental\]**

## Usage

``` r
plotCohortAttrition(
  result,
  show = c("subjects", "records"),
  type = "htmlwidget",
  cohortId = lifecycle::deprecated()
)
```

## Arguments

- result:

  A summarised_result object.

- show:

  Which variables to show in the attrition plot, it can be 'subjects',
  'records' or both.

- type:

  type of the output, it can either be: 'htmlwidget', 'png', or
  'DiagrammeR'.

- cohortId:

  deprecated.

## Value

A `grViz` visualisation.

## Examples

``` r
# \donttest{
library(CohortCharacteristics)
library(omopgenerics)
#> 
#> Attaching package: ‘omopgenerics’
#> The following object is masked from ‘package:stats’:
#> 
#>     filter
library(dplyr, warn.conflicts = FALSE)
library(clock)

cdm <- mockCohortCharacteristics(numberIndividuals = 1000)
#> Warning: There are observation period end dates after the current date: 2025-11-19
#> ℹ The latest max observation period end date found is 2038-08-17

cdm[["cohort1"]] <- cdm[["cohort1"]] |>
  filter(get_year(cohort_start_date) >= 2000) |>
  recordCohortAttrition("Restrict to cohort_start_date >= 2000") |>
  filter(get_year(cohort_end_date) < 2020) |>
  recordCohortAttrition("Restrict to cohort_end_date < 2020") |>
  compute(temporary = FALSE, name = "cohort1")

result <- summariseCohortAttrition(cdm$cohort1)

result |>
  filter(group_level == "cohort_2") |>
  plotCohortAttrition()

{"x":{"diagram":"digraph {\n\ngraph [layout = \"neato\",\n       outputorder = \"edgesfirst\",\n       bgcolor = \"white\"]\n\nnode [fontname = \"Helvetica\",\n      fontsize = \"10\",\n      shape = \"circle\",\n      fixedsize = \"true\",\n      width = \"0.5\",\n      style = \"filled\",\n      fillcolor = \"aliceblue\",\n      color = \"gray70\",\n      fontcolor = \"gray50\"]\n\nedge [fontname = \"Helvetica\",\n     fontsize = \"8\",\n     len = \"1.5\",\n     color = \"gray80\",\n     arrowsize = \"0.5\"]\n\n  \"1\" [label = \"Database: PP_MOCK\nCohort name: cohort_2\", shape = \"box\", color = \"#FFFFFF\", fillcolor = \"#FFFFFF\", fontname = \"Calibri\", fontsize = \"8\", fontcolor = \"#000000\", height = \"0.26\", width = \"1\", pos = \"0,0!\"] \n  \"2\" [label = \"N subjects = 334\nN records = 334\", shape = \"box\", color = \"#000000\", fillcolor = \"#FFFFFF\", fontname = \"Calibri\", fontsize = \"8\", fontcolor = \"#000000\", height = \"0.39\", width = \"1.2\", pos = \"0,-0.885!\"] \n  \"3\" [label = \"N subjects = 18\nN records = 18\", shape = \"box\", color = \"#000000\", fillcolor = \"#FFFFFF\", fontname = \"Calibri\", fontsize = \"8\", fontcolor = \"#000000\", height = \"0.39\", width = \"1.2\", pos = \"0,-1.965!\"] \n  \"4\" [label = \"N subjects = 13\nN records = 13\", shape = \"box\", color = \"#000000\", fillcolor = \"#FFFFFF\", fontname = \"Calibri\", fontsize = \"8\", fontcolor = \"#000000\", height = \"0.39\", width = \"1.2\", pos = \"0,-3.045!\"] \n  \"5\" [label = \"Initial qualifying events\", shape = \"box\", color = \"#000000\", fillcolor = \"#F0F8FF\", fontname = \"Calibri\", fontsize = \"8\", fontcolor = \"#000000\", height = \"0.26\", width = \"2\", pos = \"0,-0.41!\"] \n  \"6\" [label = \"Restrict to cohort_start_date >=\n2000\", shape = \"box\", color = \"#000000\", fillcolor = \"#F0F8FF\", fontname = \"Calibri\", fontsize = \"8\", fontcolor = \"#000000\", height = \"0.39\", width = \"2\", pos = \"0,-1.425!\"] \n  \"7\" [label = \"N subjects = 316\nN records = 316\", shape = \"box\", color = \"#000000\", fillcolor = \"#F8F8F8\", fontname = \"Calibri\", fontsize = \"8\", fontcolor = \"#000000\", height = \"0.39\", width = \"1.2\", pos = \"1.95,-1.425!\"] \n  \"8\" [label = \"Restrict to cohort_end_date <\n2020\", shape = \"box\", color = \"#000000\", fillcolor = \"#F0F8FF\", fontname = \"Calibri\", fontsize = \"8\", fontcolor = \"#000000\", height = \"0.39\", width = \"2\", pos = \"0,-2.505!\"] \n  \"9\" [label = \"N subjects = 5\nN records = 5\", shape = \"box\", color = \"#000000\", fillcolor = \"#F8F8F8\", fontname = \"Calibri\", fontsize = \"8\", fontcolor = \"#000000\", height = \"0.39\", width = \"1.2\", pos = \"1.95,-2.505!\"] \n\"2\"->\"3\" [color = \"#000000\"] \n\"3\"->\"4\" [color = \"#000000\"] \n\"6\"->\"7\" [color = \"#000000\"] \n\"8\"->\"9\" [color = \"#000000\"] \n}","config":{"engine":"dot","options":null}},"evals":[],"jsHooks":[]}
# }
```
