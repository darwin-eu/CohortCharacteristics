# Changelog

## CohortCharacteristics 1.1.1

CRAN release: 2026-01-28

- Update default of style and type to NULL by
  [@catalamarti](https://github.com/catalamarti) in
  [\#381](https://github.com/darwin-eu/CohortCharacteristics/issues/381)
  [\#394](https://github.com/darwin-eu/CohortCharacteristics/issues/394)
- Issue with TRUE and FALSE in LSC by
  [@catalamarti](https://github.com/catalamarti) in
  [\#391](https://github.com/darwin-eu/CohortCharacteristics/issues/391)
- Add support for ‘visit_detail’ in summariseLargeScaleCharacteristics
  by [@ilovemane](https://github.com/ilovemane) in
  [\#392](https://github.com/darwin-eu/CohortCharacteristics/issues/392)
- Refine handling of density estimates in characteristics by
  [@ilovemane](https://github.com/ilovemane) in
  [\#387](https://github.com/darwin-eu/CohortCharacteristics/issues/387)
- Handle empty cohort tables in summarise functions by
  [@ilovemane](https://github.com/ilovemane) in
  [\#383](https://github.com/darwin-eu/CohortCharacteristics/issues/383)

## CohortCharacteristics 1.1.0

CRAN release: 2025-11-19

- Add style argument to account for `visOmopResults` release by
  [@ilovemane](https://github.com/ilovemane)
  [@catalamarti](https://github.com/catalamarti) in
  [\#360](https://github.com/darwin-eu/CohortCharacteristics/issues/360)
- Add ‘Days to next record’ as part of the demographics in
  [`summariseCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseCharacteristics.md)
  by [@catalamarti](https://github.com/catalamarti) in
  [\#378](https://github.com/darwin-eu/CohortCharacteristics/issues/378)
- Add all age group (even if zero counts) in
  [`summariseCharacteristics()`](https://darwin-eu.github.io/CohortCharacteristics/reference/summariseCharacteristics.md)
  by [@catalamarti](https://github.com/catalamarti) in
  [\#378](https://github.com/darwin-eu/CohortCharacteristics/issues/378)
- Use `clock` functions for date difference by
  [@catalamarti](https://github.com/catalamarti)
  [\#367](https://github.com/darwin-eu/CohortCharacteristics/issues/367)
- Use `omock` for clean examples of mock data by catalamarti
  [\#367](https://github.com/darwin-eu/CohortCharacteristics/issues/367)
- Remove otherVariablesEstimates by
  [@ilovemane](https://github.com/ilovemane) in
  [\#362](https://github.com/darwin-eu/CohortCharacteristics/issues/362)
- Allow to use includeSource = c(T,F) by
  [@ilovemane](https://github.com/ilovemane) in
  [\#359](https://github.com/darwin-eu/CohortCharacteristics/issues/359)
- add progress message by [@ilovemane](https://github.com/ilovemane) in
  [\#372](https://github.com/darwin-eu/CohortCharacteristics/issues/372)
- improve estimate documentation by
  [@ilovemane](https://github.com/ilovemane) in
  [\#371](https://github.com/darwin-eu/CohortCharacteristics/issues/371)
- fix order in tableCharacteristics by
  [@ilovemane](https://github.com/ilovemane) in
  [\#378](https://github.com/darwin-eu/CohortCharacteristics/issues/378)
- fix png by [@ilovemane](https://github.com/ilovemane) in
  [\#377](https://github.com/darwin-eu/CohortCharacteristics/issues/377)
- emptySummarise results by [@ilovemane](https://github.com/ilovemane)
  in
  [\#370](https://github.com/darwin-eu/CohortCharacteristics/issues/370)

## CohortCharacteristics 1.0.2

CRAN release: 2025-10-23

- Update documentation by [@catalamarti](https://github.com/catalamarti)

## CohortCharacteristics 1.0.1

CRAN release: 2025-09-30

- Update tests with copyCdm() (compatibility with PatientProfiles) by
  [@catalamarti](https://github.com/catalamarti) in
  [\#357](https://github.com/darwin-eu/CohortCharacteristics/issues/357)

## CohortCharacteristics 1.0.0

CRAN release: 2025-05-20

- Stable release of the package

### New features

- includeSource -\> pair standard and source concepts in LSC by
  [@catalamarti](https://github.com/catalamarti) in
  [\#329](https://github.com/darwin-eu/CohortCharacteristics/issues/329)
- new function tableTopLargeScaleCharacteristics by
  [@catalamarti](https://github.com/catalamarti) in
  [\#335](https://github.com/darwin-eu/CohortCharacteristics/issues/335)
- refactor function tableLargeScaleCharacteristics by
  [@catalamarti](https://github.com/catalamarti) in
  [\#335](https://github.com/darwin-eu/CohortCharacteristics/issues/335)
- summariseCohortCodelist by
  [@catalamarti](https://github.com/catalamarti) in
  [\#333](https://github.com/darwin-eu/CohortCharacteristics/issues/333)

### Minor fixes

- fixes filter group by [@ilovemane](https://github.com/ilovemane) in
  [\#313](https://github.com/darwin-eu/CohortCharacteristics/issues/313)
- fixes tableintersect suppression problem by
  [@ilovemane](https://github.com/ilovemane) in
  [\#311](https://github.com/darwin-eu/CohortCharacteristics/issues/311)
- add .options for table functions by
  [@ilovemane](https://github.com/ilovemane) in
  [\#319](https://github.com/darwin-eu/CohortCharacteristics/issues/319)
- density plot for plotCharacteristics by
  [@ilovemane](https://github.com/ilovemane) in
  [\#320](https://github.com/darwin-eu/CohortCharacteristics/issues/320)
- use og functions instead of vor by
  [@catalamarti](https://github.com/catalamarti) in
  [\#332](https://github.com/darwin-eu/CohortCharacteristics/issues/332)
- improvement on vignettes. by
  [@ilovemane](https://github.com/ilovemane) in
  [\#327](https://github.com/darwin-eu/CohortCharacteristics/issues/327)
- Require-minimum-count-for-plot-timing by
  [@ilovemane](https://github.com/ilovemane) in
  [\#318](https://github.com/darwin-eu/CohortCharacteristics/issues/318)
- Fix suppressed count print by
  [@catalamarti](https://github.com/catalamarti) in
  [\#334](https://github.com/darwin-eu/CohortCharacteristics/issues/334)

## CohortCharacteristics 0.5.1

CRAN release: 2025-03-27

- Fix bug in plotCohortAttrition to not display NAs by
  [@martaalcalde](https://github.com/martaalcalde)
- Throw error if cohort table is the input of plotCohortAttrition() by
  [@catalamarti](https://github.com/catalamarti)

## CohortCharacteristics 0.5.0

CRAN release: 2025-03-18

- Update benchmarkCohortCharacteristics.R by
  [@cecicampanile](https://github.com/cecicampanile)
- fix typo in tableLargeScaleCharacteristics by
  [@catalamarti](https://github.com/catalamarti)
- fix typo in source_type by
  [@catalamarti](https://github.com/catalamarti)
- `summariseCharacteristics` cohort by cohort by
  [@cecicampanile](https://github.com/cecicampanile)
- Allow multiple cdm and cohorts in plotCohortAttrition + png format by
  [@catalamarti](https://github.com/catalamarti)
- Stack bar in plotCohortOverlap by
  [@ilovemane](https://github.com/ilovemane)
- variable_name as factor in plotCohortOverlap by
  [@catalamarti](https://github.com/catalamarti)
- none -\> unknown in summariseCharacteristics by
  [@catalamarti](https://github.com/catalamarti)
- Add weights argument to `summariseCharacteristics` by
  [@catalamarti](https://github.com/catalamarti)
- Use filterCohortId when needed by
  [@catalamarti](https://github.com/catalamarti)
- Fix ’ character in plotCohortAttrition by
  [@catalamarti](https://github.com/catalamarti)
- filter excludeCodes at the end by
  [@catalamarti](https://github.com/catalamarti)
- use \<minCellCount in tables by
  [@catalamarti](https://github.com/catalamarti)

## CohortCharacteristics 0.4.0

CRAN release: 2024-11-26

- Update links darwin-eu-dev -\> darwin-eu
  [@catalamarti](https://github.com/catalamarti)
- Typo in plotCohortAttrition by
  [@martaalcalde](https://github.com/martaalcalde)
- uniqueCombination parameter to work in a general way
  [@catalamarti](https://github.com/catalamarti)
- minimum 5 days in x axis for density plots
  [@catalamarti](https://github.com/catalamarti)
- improve documentation of minimumFrequency by
  [@catalamarti](https://github.com/catalamarti)
- add show argument to plotCohortAttrition by
  [@catalamarti](https://github.com/catalamarti)
- simplify code for overlap and fix edge case with 0 overlap by
  [@catalamarti](https://github.com/catalamarti)
- arrange ageGroups by order that they are provided in
  summariseCharacteristics by
  [@catalamarti](https://github.com/catalamarti)
- otherVariablesEstimates -\> estimates in summariseCharacteristics by
  [@catalamarti](https://github.com/catalamarti)
- add overlapBy argument to summariseCohortOverlap by
  [@catalamarti](https://github.com/catalamarti)
- Compatibility with visOmopResults 0.5.0 and omopgenerics 0.4.0 by
  [@catalamarti](https://github.com/catalamarti)
- add message if different pkg versions by
  [@catalamarti](https://github.com/catalamarti)
- make sure settings are characters by
  [@catalamarti](https://github.com/catalamarti)
- use requireEunomia and CDMConnector 1.6.0 by
  [@catalamarti](https://github.com/catalamarti)
- add benchmark function by
  [@catalamarti](https://github.com/catalamarti)
- Consistent documentation by
  [@catalamarti](https://github.com/catalamarti)
- Use subjects only when overlapBy = “subject_id” by
  [@catalamarti](https://github.com/catalamarti)
- add cohortId to LSC by [@catalamarti](https://github.com/catalamarti)

## CohortCharacteristics 0.3.0

CRAN release: 2024-10-01

- **breaking change** Complete refactor of `table*` and `plot*`
  functions following visOmopResults 0.4.0 release.
- `summarise*` functions output is always ordered in the same way.
- Added a `NEWS.md` file to track changes to the package.
