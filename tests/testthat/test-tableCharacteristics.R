test_that("tableCharacteristics", {
  skip_on_cran()
  person <- dplyr::tibble(
    person_id = c(1, 2, 3) |> as.integer(),
    gender_concept_id = c(8507, 8532, 8532) |> as.integer(),
    year_of_birth = c(1985, 2000, 1962) |> as.integer(),
    month_of_birth = c(10, 5, 9) |> as.integer(),
    day_of_birth = c(30, 10, 24) |> as.integer(),
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )
  dus_cohort <- dplyr::tibble(
    cohort_definition_id = c(1, 1, 1, 2) |> as.integer(),
    subject_id = c(1, 1, 2, 3) |> as.integer(),
    cohort_start_date = as.Date(c(
      "1990-04-19", "1991-04-19", "2010-11-14", "2000-05-25"
    )),
    cohort_end_date = as.Date(c(
      "1990-04-19", "1991-04-19", "2010-11-14", "2000-05-25"
    ))
  )
  comorbidities <- dplyr::tibble(
    cohort_definition_id = c(1, 2, 2, 1) |> as.integer(),
    subject_id = c(1, 1, 3, 3) |> as.integer(),
    cohort_start_date = as.Date(c(
      "1990-01-01", "1990-06-01", "2000-01-01", "2000-06-01"
    )),
    cohort_end_date = as.Date(c(
      "1990-01-01", "1990-06-01", "2000-01-01", "2000-06-01"
    ))
  )
  medication <- dplyr::tibble(
    cohort_definition_id = c(1, 1, 2, 1) |> as.integer(),
    subject_id = c(1, 1, 2, 3) |> as.integer(),
    cohort_start_date = as.Date(c(
      "1990-02-01", "1990-08-01", "2009-01-01", "1995-06-01"
    )),
    cohort_end_date = as.Date(c(
      "1990-02-01", "1990-08-01", "2009-01-01", "1995-06-01"
    ))
  )
  observation_period <- dplyr::tibble(
    observation_period_id = c(1, 2, 3) |> as.integer(),
    person_id = c(1, 2, 3) |> as.integer(),
    observation_period_start_date = as.Date(c(
      "1975-01-01", "1959-04-29", "1944-12-03"
    )),
    observation_period_end_date = as.Date(c(
      "2021-03-04", "2022-03-14", "2023-07-10"
    )),
    period_type_concept_id = 0L
  )

  cdm <- mockCohortCharacteristics(
    dus_cohort = dus_cohort,
    person = person,
    comorbidities = comorbidities,
    medication = medication,
    observation_period = observation_period
  ) |>
    copyCdm()

  cdm$dus_cohort <- omopgenerics::newCohortTable(
    table = cdm$dus_cohort, cohortSetRef = dplyr::tibble(
      cohort_definition_id = c(1L, 2L),
      cohort_name = c("exposed", "unexposed")
    )
  )
  cdm$comorbidities <- omopgenerics::newCohortTable(
    table = cdm$comorbidities, cohortSetRef = dplyr::tibble(
      cohort_definition_id = c(1L, 2L),
      cohort_name = c("covid", "headache")
    )
  )
  cdm$medication <- omopgenerics::newCohortTable(
    table = cdm$medication,
    cohortSetRef = dplyr::tibble(
      cohort_definition_id = c(1L, 2L, 3L),
      cohort_name = c("acetaminophen", "ibuprophen", "naloxone")
    ),
    cohortAttritionRef = NULL
  )

  result1 <- summariseCharacteristics(
    cdm$dus_cohort,
    cohortIntersectFlag = list(
      "Medications" = list(
        targetCohortTable = "medication", window = c(-365, 0)
      ),
      "Comorbidities" = list(
        targetCohortTable = "comorbidities", window = c(-Inf, 0)
      )
    )
  )

  expect_no_error(gt1 <- tableCharacteristics(result1))
  expect_true("gt_tbl" %in% class(gt1))
  expect_true(all(c("Variable name", "Variable level", "Estimate name") %in%
    colnames(gt1$`_data`)))

  fx1 <- tableCharacteristics(result1, header = c("cdm_name", "cohort_name"), type = "flextable")
  expect_true(class(fx1) == "flextable")

  tibble1 <- tableCharacteristics(result1, type = "tibble", header = character())
  expect_true(all(class(tibble1) %in% c("tbl_df", "tbl", "data.frame")))
  expect_true(all(c(
    "Variable name", "Variable level", "Estimate name",
    "CDM name", "Estimate value"
  ) %in%
    colnames(tibble1)))

  # message for different version
  result1 <- result1 |>
    omopgenerics::newSummarisedResult(
      settings = omopgenerics::settings(result1) |>
        dplyr::mutate(package_version = "0.0.0")
    )
  expect_message(tableCharacteristics(result1))

  dropCreatedTables(cdm = cdm)
})

test_that("tableCharacteristics, empty output warning message", {
  skip_on_cran()
  expect_warning(x <- tableCharacteristics(
    result = omopgenerics::emptySummarisedResult(), type = "gt"
  ))
  expect_true(inherits(x, "gt_tbl"))
})
