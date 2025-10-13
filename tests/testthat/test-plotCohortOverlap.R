test_that("plotCohortOverlap", {
  skip_on_cran()
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
    cohort_definition_id = c(rep(1, 15), rep(2, 10), rep(3, 15), rep(4, 5)) |>
      as.integer(),
    subject_id = c(
      20, 5, 10, 12, 4, 15, 2, 1, 5, 10, 5, 8, 13, 4, 10,
      6, 18, 5, 1, 20, 14, 13, 8, 17, 3,
      16, 15, 20, 17, 3, 14, 6, 11, 8, 7, 20, 19, 5, 2, 18,
      5, 12, 3, 14, 13
    ) |> as.integer(),
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
    person = person,
    observation_period = obs, table = table
  ) |>
    copyCdm()

  overlap <- summariseCohortOverlap(cdm$table)

  gg1 <- plotCohortOverlap(overlap)
  expect_true("ggplot" %in% class(gg1))
  # expect_false("cohort_4" %in% gg1$data$cohort_name_reference)

  gg2 <- plotCohortOverlap(
    overlap,
    facet = "cdm_name",
    uniqueCombinations = TRUE
  )
  expect_true("ggplot" %in% class(gg2))
  #filter cohort check
  expect_no_error(
    CohortCharacteristics::plotCohortOverlap(
      overlap |>
        omopgenerics::filterGroup(cohort_name_comparator  %in%
                                    "cohort_1"),
      facet = c("cdm_name", "cohort_name_reference")
    )
  )

  expect_no_error(
    CohortCharacteristics::plotCohortOverlap(
      overlap |>
        omopgenerics::filterGroup(cohort_name_reference  %in%
                                    "cohort_1"),
      facet = c("cdm_name", "cohort_name_comparator")
    )
  )

  # strata ----
  cdm$table <- cdm$table |>
    PatientProfiles::addAge(ageGroup = list(c(0, 40), c(41, 150))) |>
    PatientProfiles::addSex() |>
    dplyr::compute(name = "table", temporary = FALSE) |>
    omopgenerics::newCohortTable()

  overlap2 <- summariseCohortOverlap(cdm$table,
    strata = list("age_group", c("age_group", "sex"))
  )

  gg3 <- plotCohortOverlap(
    overlap2,
    facet = c("age_group", "sex"),
    uniqueCombinations = TRUE
  )
  expect_true("ggplot" %in% class(gg3))

  # > 1 CDM
  overlap3 <- overlap |>
    dplyr::union_all(
      overlap |>
        dplyr::mutate(cdm_name = "cdm2") |>
        dplyr::filter(.data$group_level != "cohort_2 &&& cohort_4")
    )
  gg4 <- plotCohortOverlap(
    overlap3, facet = "cdm_name", uniqueCombinations = FALSE
  )

  dropCreatedTables(cdm = cdm)
})
