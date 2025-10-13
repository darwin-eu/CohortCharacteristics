test_that("check summariseCohortAttrition is deterministic", {
  cdm <- mockCohortCharacteristics(numberIndividuals = 1000) |>
    copyCdm()

  cdm$cohort1 <- cdm$cohort1 |>
    dplyr::filter(cohort_start_date >= as.Date("2000-01-01")) |>
    omopgenerics::recordCohortAttrition("Restrict to cohort_start_date >= 2000") |>
    dplyr::filter(cohort_end_date < as.Date("2020-01-01")) |>
    omopgenerics::recordCohortAttrition("Restrict to cohort_end_date < 2020") |>
    dplyr::compute(temporary = FALSE, name = "cohort1")

  att <- omopgenerics::attrition(cdm$cohort1)
  att1 <- att |> dplyr::arrange(dplyr::desc(.data$cohort_definition_id))
  set <- omopgenerics::settings(cdm$cohort1) |>
    dplyr::mutate("result_id" = as.integer(dplyr::row_number()))
  set1 <- set |> dplyr::arrange(dplyr::desc(.data$cohort_definition_id))
  tn <- omopgenerics::tableName(cdm$cohort1)
  cn <- omopgenerics::cdmName(cdm$cohort1)

  expect_no_error(x1 <- summariseAttrition(att, set, tn, cn))
  expect_no_error(x2 <- summariseAttrition(att1, set, tn, cn))
  expect_no_error(x3 <- summariseAttrition(att, set1, tn, cn))
  expect_no_error(x4 <- summariseAttrition(att1, set1, tn, cn))

  expect_identical(x1, x2)
  expect_identical(x1, x3)
  expect_identical(x1, x4)

  dropCreatedTables(cdm = cdm)
})
