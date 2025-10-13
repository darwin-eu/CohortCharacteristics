# CohortCharacteristics 1.0.1

* Update tests with copyCdm() (compatibility with PatientProfiles) by @catalamarti in #357

# CohortCharacteristics 1.0.0

* Stable release of the package

## New features
* includeSource -> pair standard and source concepts in LSC by @catalamarti in #329
* new function tableTopLargeScaleCharacteristics by @catalamarti in #335
* refactor function tableLargeScaleCharacteristics by @catalamarti in #335
* summariseCohortCodelist by @catalamarti in #333

## Minor fixes
* fixes filter group by @ilovemane in #313
* fixes tableintersect suppression problem by @ilovemane in #311
* add .options for table functions by @ilovemane in #319
* density plot for plotCharacteristics by @ilovemane in #320
* use og functions instead of vor by @catalamarti in #332
* improvement on vignettes. by @ilovemane in #327
* Require-minimum-count-for-plot-timing by @ilovemane in #318
* Fix suppressed count print by @catalamarti in #334

# CohortCharacteristics 0.5.1

* Fix bug in plotCohortAttrition to not display NAs by @martaalcalde
* Throw error if cohort table is the input of plotCohortAttrition() by @catalamarti

# CohortCharacteristics 0.5.0

* Update benchmarkCohortCharacteristics.R by @cecicampanile
* fix typo in tableLargeScaleCharacteristics by @catalamarti
* fix typo in source_type by @catalamarti
* `summariseCharacteristics` cohort by cohort by @cecicampanile
* Allow multiple cdm and cohorts in plotCohortAttrition + png format by @catalamarti
* Stack bar in plotCohortOverlap by @ilovemane
* variable_name as factor in plotCohortOverlap by @catalamarti
* none -> unknown in summariseCharacteristics by @catalamarti
* Add weights argument to `summariseCharacteristics` by @catalamarti
* Use filterCohortId when needed by @catalamarti
* Fix ' character in plotCohortAttrition by @catalamarti
* filter excludeCodes at the end by @catalamarti
* use <minCellCount in tables by @catalamarti

# CohortCharacteristics 0.4.0

* Update links darwin-eu-dev -> darwin-eu @catalamarti
* Typo in plotCohortAttrition by @martaalcalde
* uniqueCombination parameter to work in a general way @catalamarti
* minimum 5 days in x axis for density plots @catalamarti
* improve documentation of minimumFrequency by @catalamarti
* add show argument to plotCohortAttrition by @catalamarti
* simplify code for overlap and fix edge case with 0 overlap by @catalamarti
* arrange ageGroups by order that they are provided in summariseCharacteristics by @catalamarti
* otherVariablesEstimates -> estimates in summariseCharacteristics by @catalamarti
* add overlapBy argument to summariseCohortOverlap by @catalamarti
* Compatibility with visOmopResults 0.5.0 and omopgenerics 0.4.0 by @catalamarti
* add message if different pkg versions by @catalamarti
* make sure settings are characters by @catalamarti
* use requireEunomia and CDMConnector 1.6.0 by @catalamarti
* add benchmark function by @catalamarti
* Consistent documentation by @catalamarti
* Use subjects only when overlapBy = "subject_id" by @catalamarti
* add cohortId to LSC by @catalamarti

# CohortCharacteristics 0.3.0

* **breaking change** Complete refactor of `table*` and `plot*` functions 
  following visOmopResults 0.4.0 release.
* `summarise*` functions output is always ordered in the same way.
* Added a `NEWS.md` file to track changes to the package.
