test_that("multiplication works", {
  skip_on_cran()
  cdm <- mockCohortCharacteristics() |>
    copyCdm()
  result <- summariseCharacteristics(cdm$cohort1)
  expect_no_error(apc <- availablePlotColumns(result))
  expect_no_error(atc <- availableTableColumns(result))
  dropCreatedTables(cdm = cdm)
})
