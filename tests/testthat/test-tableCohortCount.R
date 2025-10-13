test_that("tableCohortCount", {
  skip_on_cran()
  cdm <- mockCohortCharacteristics(numberIndividuals = 100) |>
    copyCdm()

  counts <- cdm$cohort2 |>
    PatientProfiles::addSex() |>
    PatientProfiles::addAge(ageGroup = list(c(0, 29), c(30, 59), c(60, Inf))) |>
    summariseCohortCount(strata = list("age_group", "sex", c("age_group", "sex"))) |>
    dplyr::filter(variable_name == "Number subjects")

  expect_no_error(tbl <- tableCohortCount(counts))
  expect_true(inherits(tbl, "gt_tbl"))

  dropCreatedTables(cdm = cdm)
})
