# CohortCharacteristics 0.4.0

* Update links darwin-eu-dev -> darwin-eu @catalamarti
* Typo in plotCohortAttrition by @martaalcalde
* uniqueCombination paramters to work in a general way @catalamarti
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
