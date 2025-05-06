test_that("benchmark", {
  skip_on_cran()

  cdm <- duckdb::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir()) |>
    CDMConnector::cdmFromCon(cdmSchema = "main", writeSchema = "main") |>
    CDMConnector::generateConceptCohortSet(
      conceptSet = list(sinusitis = 40481087, pharyngitis = 4112343),
      name = "my_cohort"
    )

  expect_no_error(res <- benchmarkCohortCharacteristics(cdm$my_cohort))
  expect_true(inherits(res, "summarised_result"))
  expect_identical(settings(res) |> dplyr::pull("source_type"), "duckdb")

  expect_no_error(res <- benchmarkCohortCharacteristics(cdm$my_cohort, analysis = character()))
  expect_true(inherits(res, "summarised_result"))
  expect_true(nrow(res) == 0)

})
