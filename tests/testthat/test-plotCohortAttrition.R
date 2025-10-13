test_that("plot cohort attrition", {
  cdm <- mockCohortCharacteristics(numberIndividuals = 1000) |>
    copyCdm()

  cdm[["cohort1"]] <- cdm[["cohort1"]] |>
    dplyr::filter(cohort_start_date >= as.Date("2000-01-01")) |>
    omopgenerics::recordCohortAttrition("Restrict to cohort_start_date >= 2000") |>
    dplyr::filter(cohort_end_date < as.Date("2020-01-01")) |>
    omopgenerics::recordCohortAttrition("Restrict to cohort_end_date < 2020") |>
    dplyr::compute(temporary = FALSE, name = "cohort1")

  ca <- cdm[["cohort1"]] |> summariseCohortAttrition()

  expect_warning(x <- plotCohortAttrition(ca, cohortId = 2))

  expect_true(inherits(x, c("grViz", "htmlwidget")))

  # Test empty data
  ca <- ca |> dplyr::filter(result_id == 10)
  expect_warning(x <- plotCohortAttrition(ca))
  expect_true(inherits(x, c("grViz", "htmlwidget")))

  # Test other result
  other <- PatientProfiles::summariseResult(cdm[["cohort1"]])
  expect_warning(x <- plotCohortAttrition(other))
  expect_true(inherits(x, c("grViz", "htmlwidget")))

  # subset to just one cohort
  cdm$cohort1 <- CohortConstructor::subsetCohorts(cdm$cohort1, cohortId = 1)
  out <- cdm$cohort1 |>
    summariseCohortAttrition() |>
    plotCohortAttrition()

  # test attrition object (to consider if this is needed)
  expect_no_error(plotCohortAttrition(omopgenerics::attrition(cdm$cohort1)))

  # test cohort object (to consider if this is needed)
  expect_error(plotCohortAttrition(cdm$cohort1))

  dropCreatedTables(cdm = cdm)
})
