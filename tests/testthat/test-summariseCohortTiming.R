test_that("summariseCohortTiming", {
  person <- dplyr::tibble(
    person_id = 1:20L,
    gender_concept_id = 8532L,
    year_of_birth = sample(1950:2000L, size = 20, replace = TRUE),
    month_of_birth = sample(1:12L, size = 20, replace = TRUE),
    day_of_birth = sample(1:28L, size = 20, replace = TRUE),
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )

  table <- dplyr::tibble(
    cohort_definition_id = c(rep(1L, 15), rep(2L, 10), rep(3L, 15), rep(4L, 5)),
    subject_id = purrr::map(1:9, \(x) sample(1:20L, size = 5)) |> unlist(),
    cohort_start_date = as.Date(c(
      rep("2000-01-01", 5), rep("2010-09-05", 5), rep("2006-05-01", 5),
      rep("2003-03-31", 5), rep("2008-07-02", 5), rep("2000-01-01", 5),
      rep("2012-09-05", 5), rep("1996-05-01", 5), rep("1989-03-31", 5)
    )),
    cohort_end_date = as.Date(c(
      rep("2000-01-01", 5), rep("2010-09-05", 5), rep("2006-05-01", 5),
      rep("2003-03-31", 5), rep("2008-07-02", 5), rep("2000-01-01", 5),
      rep("2012-09-05", 5), rep("1996-05-01", 5), rep("1989-03-31", 5)
    ))
  )

  obs <- dplyr::tibble(
    observation_period_id = 1:20L,
    person_id = 1:20L,
    observation_period_start_date = as.Date("1930-01-01"),
    observation_period_end_date = as.Date("2025-01-01"),
    period_type_concept_id = 0L
  )

  cdm <- mockCohortCharacteristics(
    person = person, observation_period = obs, table = table
  ) |>
    copyCdm()

  timing1 <- summariseCohortTiming(cdm$table,
    restrictToFirstEntry = TRUE
  )

  expect_equal(
    omopgenerics::resultColumns("summarised_result"),
    colnames(timing1)
  )

  expect_true(all(c("min", "q25", "median", "q75", "max", "count") %in%
    timing1$estimate_name |> unique()))
  expect_true(as.logical(omopgenerics::settings(timing1)$restrict_to_first_entry))

  timing2 <- summariseCohortTiming(cdm$table,
    restrictToFirstEntry = FALSE,
    estimates = c("min", "max")
  )
  expect_equal(
    omopgenerics::resultColumns("summarised_result"),
    colnames(timing2)
  )
  expect_true(all(timing2$estimate_name |> unique() %in%
    c("min", "max", "count")))

  timing3 <- summariseCohortTiming(cdm$table,
    restrictToFirstEntry = FALSE,
    estimates = c("density")
  )
  expect_true(all(c("density_x", "density_y") %in%
    unique(timing3$estimate_name)))
  expect_true("overall" == unique(timing3$strata_level))
  expect_no_error(res1 <- tidyr::pivot_wider(timing3, names_from = "estimate_name", values_from = "estimate_value"))
  expect_true(all(c("density_x", "density_y") %in% colnames(res1)))
  expect_true(class(res1$density_x) == "character")

  ## Strata and cohortId----
  cdm$table <- cdm$table |>
    PatientProfiles::addAge(ageGroup = list(c(0, 40), c(41, 150))) |>
    PatientProfiles::addSex() |>
    dplyr::compute(name = "table", temporary = FALSE) |>
    omopgenerics::newCohortTable()
  timing4 <- summariseCohortTiming(cdm$table,
    strata = list("age_group", c("age_group", "sex"))
  )
  expect_true(all(c("overall", "age_group", "age_group &&& sex") %in%
    unique(timing4$strata_name)))

  # add density tests
  timing5 <- summariseCohortTiming(cdm$table,
    strata = list("age_group", c("age_group", "sex")),
    estimates = "density"
  )
  expect_true(all(unique(timing5$estimate_name[timing5$strata_name == "age_group &&& sex"]) %in% c("density_x", "density_y", "count")))
  expect_true(all(unique(timing5$estimate_name[timing5$strata_name == "overall"]) %in% c("density_x", "density_y", "count")))
  expect_true(all(unique(timing5$estimate_name[timing5$strata_name == "age_group"]) %in% c("density_x", "density_y", "count")))
  expect_no_error(res2 <- tidyr::pivot_wider(timing5, names_from = "estimate_name", values_from = "estimate_value"))
  expect_true(all(c("density_x", "density_y") %in% colnames(res2)))
  expect_true(class(res2$density_x) == "character")

  timing6 <- summariseCohortTiming(cdm$table, cohortId = 1)
  expect_true(nrow(timing6) == 0)

  expect_error(timing7 <- summariseCohortTiming(cdm$table, cohortId = 5))

  dropCreatedTables(cdm = cdm)
})

test_that("result is deterministic", {
  set.seed(123456)
  cdm <- omock::mockCdmReference() |>
    omock::mockPerson(nPerson = 100) |>
    omock::mockObservationPeriod() |>
    omock::mockCohort(numberCohorts = 3, cohortName = c("covid", "tb", "asthma"))
  cdm$cohort <- cdm$cohort |>
    dplyr::inner_join(
      cdm$person |>
        dplyr::select("subject_id" = "person_id") |>
        dplyr::mutate(idep = paste0("Q", sample(1:4L, dplyr::n(), replace = TRUE))),
      by = "subject_id"
    )
  aG <- list("<=20" = c(0, 20), ">20" = c(21, Inf))
  st <- list("sex", "idep", "age_group", c("age_group", "sex"))

  cdm1 <- copyCdm(cdm = cdm)
  cdm1$cohort <- cdm1$cohort |>
    PatientProfiles::addDemographics(
      age = FALSE, priorObservation = FALSE, futureObservation = FALSE,
      ageGroup = aG, name = "cohort"
    ) |>
    omopgenerics::newCohortTable()

  # cdm2 <- cdm
  # cdm2$cohort <- cdm2$cohort |>
  #   PatientProfiles::addDemographics(
  #     age = FALSE, priorObservation = FALSE, futureObservation = FALSE,
  #     ageGroup = aG, name = "cohort"
  #   ) |>
  #   omopgenerics::newCohortTable()

  result1 <- cdm1$cohort |>
    summariseCohortTiming(
      strata = st, estimates = c("min", "q25", "median", "q75", "max")
    )

  # TODO
  # result2 <- cdm2$cohort |>
  #   summariseCohortTiming(
  #     strata = st, estimates = c("min", "q25", "median", "q75", "max")
  #   )
  #
  # expect_identical(result1, result2)

  dropCreatedTables(cdm = cdm1)
})
