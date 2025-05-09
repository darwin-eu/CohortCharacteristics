# Test 1: Function returns a ggplot object
test_that("Function returns a ggplot object", {
  skip_on_cran()
  person <- dplyr::tibble(
    person_id = c(1, 2) |> as.integer(),
    gender_concept_id = c(8507, 8532) |> as.integer(),
    year_of_birth = c(1990, 1992) |> as.integer(),
    month_of_birth = c(1, 1) |> as.integer(),
    day_of_birth = c(1, 1) |> as.integer(),
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )
  observation_period <- dplyr::tibble(
    observation_period_id = c(1, 2) |> as.integer(),
    person_id = c(1, 2) |> as.integer(),
    observation_period_start_date = as.Date(c("2011-10-07", "2000-01-01")),
    observation_period_end_date = as.Date(c("2031-10-07", "2030-01-01")),
    period_type_concept_id = 44814724L
  )
  cohort_interest <- dplyr::tibble(
    cohort_definition_id = c(1, 1, 1, 2) |> as.integer(),
    subject_id = c(1, 1, 2, 2) |> as.integer(),
    cohort_start_date = as.Date(c(
      "2012-10-10", "2015-01-01", "2013-10-10", "2015-01-01"
    )),
    cohort_end_date = as.Date(c(
      "2012-10-10", "2015-01-01", "2013-10-10", "2015-01-01"
    ))
  )
  drug_exposure <- dplyr::tibble(
    drug_exposure_id = 1:11L,
    person_id = c(rep(1, 8), rep(2, 3)) |> as.integer(),
    drug_concept_id = c(
      rep(1125315, 2), rep(1503328, 5), 1516978, 1125315, 1503328, 1516978
    ) |> as.integer(),
    drug_exposure_start_date = as.Date(c(
      "2010-10-01", "2012-12-31", "2010-01-01", "2012-09-01", "2013-04-01",
      "2014-10-31", "2015-05-01", "2015-10-01", "2012-01-01", "2012-10-01",
      "2014-10-12"
    )),
    drug_exposure_end_date = as.Date(c(
      "2010-12-01", "2013-05-12", "2011-01-01", "2012-10-01", "2013-05-01",
      "2014-12-31", "2015-05-02", "2016-10-01", "2012-01-01", "2012-10-30",
      "2015-01-10"
    )),
    drug_type_concept_id = 38000177L,
    quantity = 1L
  )
  condition_occurrence <- dplyr::tibble(
    condition_occurrence_id = 1:8L,
    person_id = c(rep(1, 4), rep(2, 4)) |> as.integer(),
    condition_concept_id = c(
      317009, 378253, 378253, 4266367, 317009, 317009, 378253, 4266367
    ) |> as.integer(),
    condition_start_date = as.Date(c(
      "2012-10-01", "2012-01-01", "2014-01-01", "2010-01-01", "2015-02-01",
      "2012-01-01", "2013-10-01", "2014-10-10"
    )),
    condition_end_date = as.Date(c(
      "2013-01-01", "2012-04-01", "2014-10-12", "2015-01-01", "2015-03-01",
      "2012-04-01", "2013-12-01", NA
    )),
    condition_type_concept_id = 32020L
  )
  cdm <- mockCohortCharacteristics(
    person = person, observation_period = observation_period,
    cohort_interest = cohort_interest, drug_exposure = drug_exposure,
    condition_occurrence = condition_occurrence
  )

  concept <- dplyr::tibble(
    concept_id = c(1125315, 1503328, 1516978, 317009, 378253, 4266367) |> as.integer(),
    domain_id = NA_character_,
    vocabulary_id = NA_character_,
    concept_class_id = NA_character_,
    concept_code = NA_character_,
    valid_start_date = as.Date("1900-01-01"),
    valid_end_date = as.Date("2099-01-01")
  ) |>
    dplyr::mutate(concept_name = paste0("concept: ", .data$concept_id))

  cdm <- CDMConnector::insertTable(cdm, "concept", concept)

  test_data <- cdm$cohort_interest |>
    PatientProfiles::addDemographics(
      ageGroup = list(c(0, 24), c(25, 150))
    ) |>
    summariseLargeScaleCharacteristics(
      strata = list("age_group", c("age_group", "sex")),
      episodeInWindow = c("condition_occurrence", "drug_exposure"),
      minimumFrequency = 0
    )

  plot_multiple <- plotLargeScaleCharacteristics(
    result = test_data |>
      dplyr::filter(group_level %in% c("cohort_1", "cohort_2")),
    facet = c("variable_level", "cohort_name"),
    colour = c("age_group", "sex")
  )

  expect_true(ggplot2::is_ggplot(plot_multiple))

  # do not throw error even if they do not specify color or facet or position
  expect_no_error(plotLargeScaleCharacteristics(test_data))

  plot_multiple <- plotComparedLargeScaleCharacteristics(
    result = test_data |>
      dplyr::filter(group_level == "cohort_1"),
    colour = "variable_level",
    reference = "-inf to -366",
    facet = age_group ~ sex,
    missings = 0
  )

  # do not throw error even if they do not specify color or facet or position
  expect_true(ggplot2::is_ggplot(plot_multiple))
})

test_that("output is always the same", {
  set.seed(123456)
  cdm <- omock::mockCdmReference() |>
    omock::mockPerson(nPerson = 100) |>
    omock::mockObservationPeriod() |>
    omock::mockConditionOccurrence(recordPerson = 3) |>
    omock::mockCohort(
      numberCohorts = 3, cohortName = c("covid", "tb", "asthma")
    )

  cdm1 <- CDMConnector::copyCdmTo(
    con = duckdb::dbConnect(duckdb::duckdb()), cdm = cdm, schema = "main"
  )

  cdm2 <- CDMConnector::copyCdmTo(
    con = duckdb::dbConnect(duckdb::duckdb()), cdm = cdm, schema = "main"
  )

  result1 <- cdm1$cohort |>
    summariseLargeScaleCharacteristics(eventInWindow = "condition_occurrence")

  result2 <- cdm2$cohort |>
    summariseLargeScaleCharacteristics(eventInWindow = "condition_occurrence")

  expect_identical(result1, result2)

  PatientProfiles::mockDisconnect(cdm = cdm)
})
