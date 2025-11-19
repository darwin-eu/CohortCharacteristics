# Package index

### Summarise patient characteristic standard function

- [`summariseCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseCharacteristics.md)
  : Summarise characteristics of cohorts in a cohort table
- [`summariseCohortAttrition()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseCohortAttrition.md)
  : Summarise attrition associated with cohorts in a cohort table
- [`summariseCohortCodelist()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseCohortCodelist.md)
  **\[experimental\]** : Summarise the cohort codelist attribute
- [`summariseCohortCount()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseCohortCount.md)
  : Summarise counts for cohorts in a cohort table
- [`summariseCohortOverlap()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseCohortOverlap.md)
  : Summarise overlap between cohorts in a cohort table
- [`summariseCohortTiming()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseCohortTiming.md)
  : Summarise timing between entries into cohorts in a cohort table
- [`summariseLargeScaleCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseLargeScaleCharacteristics.md)
  : This function is used to summarise the large scale characteristics
  of a cohort table

### Create visual tables from summarised objects

- [`tableCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/tableCharacteristics.md)
  **\[experimental\]** : Format a summarise_characteristics object into
  a visual table.

- [`tableCohortAttrition()`](https://darwin-eu.github.io/CohortCharacteristics/reference/tableCohortAttrition.md)
  **\[experimental\]** : Create a visual table from the output of
  summariseCohortAttrition.

- [`tableCohortCodelist()`](https://darwin-eu.github.io/CohortCharacteristics/reference/tableCohortCodelist.md)
  **\[experimental\]** :

  Create a visual table from `<summarised_result>` object from
  [`summariseCohortCodelist()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseCohortCodelist.md)

- [`tableCohortCount()`](https://darwin-eu.github.io/CohortCharacteristics/reference/tableCohortCount.md)
  **\[experimental\]** : Format a summarise_characteristics object into
  a visual table.

- [`tableCohortOverlap()`](https://darwin-eu.github.io/CohortCharacteristics/reference/tableCohortOverlap.md)
  **\[experimental\]** : Format a summariseOverlapCohort result into a
  visual table.

- [`tableCohortTiming()`](https://darwin-eu.github.io/CohortCharacteristics/reference/tableCohortTiming.md)
  **\[experimental\]** : Format a summariseCohortTiming result into a
  visual table.

- [`tableLargeScaleCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/tableLargeScaleCharacteristics.md)
  : Explore and compare the large scale characteristics of cohorts

- [`tableTopLargeScaleCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/tableTopLargeScaleCharacteristics.md)
  : Visualise the top concepts per each cdm name, cohort, statification
  and window.

- [`availableTableColumns()`](https://darwin-eu.github.io/CohortCharacteristics/reference/availableTableColumns.md)
  :

  Available columns to use in `header`, `groupColumn` and `hide`
  arguments in table functions.

### Generate ggplot2 plots from summarised_result objects

Functions to generate plots (ggplot2) from summarised objects.

- [`plotCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/plotCharacteristics.md)
  **\[experimental\]** : Create a ggplot from the output of
  summariseCharacteristics.

- [`plotCohortAttrition()`](https://darwin-eu.github.io/CohortCharacteristics/reference/plotCohortAttrition.md)
  **\[experimental\]** : create a ggplot from the output of
  summariseLargeScaleCharacteristics.

- [`plotCohortCount()`](https://darwin-eu.github.io/CohortCharacteristics/reference/plotCohortCount.md)
  **\[experimental\]** : Plot the result of summariseCohortCount.

- [`plotCohortOverlap()`](https://darwin-eu.github.io/CohortCharacteristics/reference/plotCohortOverlap.md)
  **\[experimental\]** : Plot the result of summariseCohortOverlap.

- [`plotCohortTiming()`](https://darwin-eu.github.io/CohortCharacteristics/reference/plotCohortTiming.md)
  **\[experimental\]** : Plot summariseCohortTiming results.

- [`plotComparedLargeScaleCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/plotComparedLargeScaleCharacteristics.md)
  **\[experimental\]** : create a ggplot from the output of
  summariseLargeScaleCharacteristics.

- [`plotLargeScaleCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/plotLargeScaleCharacteristics.md)
  **\[experimental\]** : create a ggplot from the output of
  summariseLargeScaleCharacteristics.

- [`availablePlotColumns()`](https://darwin-eu.github.io/CohortCharacteristics/reference/availablePlotColumns.md)
  :

  Available columns to use in `facet` and `colour` arguments in plot
  functions.

### Benchmark

- [`benchmarkCohortCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/benchmarkCohortCharacteristics.md)
  : Benchmark the main functions of CohortCharacteristics package.

### Helper functions

- [`mockCohortCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/mockCohortCharacteristics.md)
  : It creates a mock database for testing CohortCharacteristics package
