test_that("tableCohortAttrition", {
  skip_on_cran()
  cdm <- mockCohortCharacteristics()

  result <- summariseCohortAttrition(cdm$cohort2)

  expect_no_error(tbl <- tableCohortAttrition(result))
  expect_true(inherits(tbl, "gt_tbl"))

  mockDisconnect(cdm)
})
