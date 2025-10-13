test_that("test summarise cohortCodelist attribute", {
  # no attribute
  cdm <- mockCohortCharacteristics() |>
    copyCdm()

  expect_no_error(res <- summariseCohortCodelist(cohort = cdm$cohort1))
  expect_true(inherits(res, "summarised_result"))
  expect_true(nrow(res) == 0)
  expect_warning(tableCohortCodelist(res))
  expect_warning(tableCohortCodelist(omopgenerics::emptySummarisedResult()))
  omopgenerics::cdmDisconnect(cdm = cdm)

  # add codelist
  my_cohort <- dplyr::tibble(
    cohort_definition_id = 1L, subject_id = 1L,
    cohort_start_date = as.Date("2020-01-01"),
    cohort_end_date = as.Date("2020-01-01")
  )
  cdm <- mockCohortCharacteristics(my_cohort = my_cohort) |>
    copyCdm()

  cdm$my_cohort <- cdm$my_cohort |>
    omopgenerics::newCohortTable(cohortCodelistRef = dplyr::tibble(
      cohort_definition_id = 1L,
      codelist_name = c(rep("codelist_1", 4), "codelist_2", "codelist_3", "codelist_4"),
      concept_id = c(1L, 2L, 4L, 5L, 1L, 4L, 5L),
      codelist_type = c(rep("index event", 4), rep("inclusion criteria", 2), "exit criteria")
    ))
  expect_error(res <- summariseCohortCodelist(cohort = cdm$my_cohort))
  cdm <- omopgenerics::insertTable(cdm = cdm, name = "concept", table = dplyr::tibble(
    concept_id = 1:5L,
    concept_name = c("abc", "def", "fras", "Dewcds", "mcecods"),
    domain_id = NA_character_,
    vocabulary_id = NA_character_,
    concept_class_id = NA_character_,
    concept_code = NA_character_,
    valid_start_date = as.Date(NA_character_),
    valid_end_date = as.Date(NA_character_)
  ))
  expected <- dplyr::tibble(
    cdm_name = "PP_MOCK",
    cohort_name = "cohort_1",
    codelist_name = c(rep("codelist_1", 4), "codelist_2", "codelist_3", "codelist_4"),
    codelist_type = c(rep("index event", 4), rep("inclusion criteria", 2), "exit criteria"),
    variable_name = "overall",
    variable_level = "overall",
    concept_name = c("abc", "def", "Dewcds", "mcecods", "abc", "Dewcds", "mcecods"),
    concept_id = c(1L, 2L, 4L, 5L, 1L, 4L, 5L)
  )
  expect_no_error(res <- summariseCohortCodelist(cohort = cdm$my_cohort))
  expect_true(inherits(res, "summarised_result"))
  expect_true(nrow(res) == 7)
  expect_identical(dplyr::as_tibble(omopgenerics::tidy(res)), expected)
  expected <- expected |>
    dplyr::select(!c("variable_name", "variable_level"))
  expect_true(inherits(tableCohortCodelist(res), "reactable"))
  expect_true(inherits(tableCohortCodelist(res, type = "tibble"), "tbl"))
  expect_true(inherits(tableCohortCodelist(res, type = "gt"), "gt_tbl"))
  expect_true(inherits(tableCohortCodelist(res, type = "flextable"), "flextable"))
  expect_true(inherits(tableCohortCodelist(res, type = "datatable"), "datatables"))
  expect_true(inherits(tableCohortCodelist(res, type = "reactable"), "reactable"))

  dropCreatedTables(cdm = cdm)
})
