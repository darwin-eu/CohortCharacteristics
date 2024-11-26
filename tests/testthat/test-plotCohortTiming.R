test_that("plotCohortTiming, boxplot", {
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
    cohort_definition_id = c(rep(1, 15), rep(2, 10), rep(3, 15), rep(4, 5)) |> as.integer(),
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
    con = connection(), writeSchema = writeSchema(),
    person = person, observation_period = obs, table = table
  )

  timing1 <- summariseCohortTiming(cdm$table,
    restrictToFirstEntry = TRUE
  )
  boxplot1 <- plotCohortTiming(timing1,
    facet = "cdm_name",
    colour = c("cohort_name_reference", "cohort_name_comparator"),
    uniqueCombinations = TRUE
  )
  # expect_true(all(c("q0", "q25", "q50", "q75", "q100") %in% colnames(boxplot1$data)))
  # expect_true(all(c("Cohort 1", "Cohort 2") %in% boxplot1$data$cohort_name_reference))
  # expect_true(all(c("Cohort 2", "Cohort 3", "Cohort 4") %in% boxplot1$data$cohort_name_comparator))
  # expect_false("Cohort 1" %in% boxplot1$data$cohort_name_comparator)
  expect_true(all(c("gg", "ggplot") %in% class(boxplot1)))
  # expect_true(boxplot1$labels$fill == "group")

  boxplot2 <- plotCohortTiming(timing1,
    colour = c("cohort_name_comparator"),
    uniqueCombinations = FALSE
  )
  # expect_true(all(c("Cohort 1", "Cohort 2") %in% boxplot2$data$cohort_name_reference))
  # expect_true(all(c("Cohort 1", "Cohort 2", "Cohort 3", "Cohort 4") %in% boxplot2$data$cohort_name_comparator))
  expect_true(all(c("gg", "ggplot") %in% class(boxplot2)))

  # strata
  cdm$table <- cdm$table |>
    PatientProfiles::addAge(ageGroup = list(c(0, 40), c(41, 150))) |>
    PatientProfiles::addSex() |>
    dplyr::compute(name = "table", temporary = FALSE) |>
    omopgenerics::newCohortTable()
  timing3 <- summariseCohortTiming(cdm$table,
    strata = list("age_group", c("age_group", "sex")),
    restrictToFirstEntry = FALSE
  )
  boxplot3 <- plotCohortTiming(timing3,
    colour = c("age_group", "sex"),
    facet = c("age_group", "sex"),
    uniqueCombinations = FALSE
  )
  # expect_true(all(c("Cohort 1", "Cohort 2") %in% boxplot3$data$cohort_name_reference))
  # expect_true(all(c("Cohort 1", "Cohort 2", "Cohort 3", "Cohort 4") %in% boxplot3$data$cohort_name_comparator))
  expect_true(all(c("gg", "ggplot") %in% class(boxplot3)))
  # expect_true(boxplot3$labels$fill == "group")
  # expect_true(all(c("overall", "0 to 40", "0 to 40 &&& Female", "41 to 150", "41 to 150 &&& Female") %in% unique(boxplot3$data$color_combined)))

  mockDisconnect(cdm)
})

test_that("plotCohortTiming, density", {
  skip_on_cran()
  person <- dplyr::tibble(
    person_id = 1:20L,
    year_of_birth = sample(1950:2000L, size = 20, replace = TRUE),
    month_of_birth = sample(1:12, size = 20, replace = TRUE),
    day_of_birth = sample(1:28, size = 20, replace = TRUE),
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  ) |>
    dplyr::mutate(gender_concept_id = sample(c(8532, 8507), size = dplyr::n(), replace = TRUE))

  table <- dplyr::tibble(
    cohort_definition_id = c(rep(1, 15), rep(2, 10), rep(3, 15), rep(4, 5)) |> as.integer(),
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
    observation_period_id = 1:20 |> as.integer(),
    person_id = 1:20 |> as.integer(),
    observation_period_start_date = as.Date("1930-01-01"),
    observation_period_end_date = as.Date("2025-01-01"),
    period_type_concept_id = 0L
  )

  cdm <- mockCohortCharacteristics(
    con = connection(), writeSchema = writeSchema(),
    person = person, observation_period = obs, table = table
  )

  timing1 <- summariseCohortTiming(cdm$table, restrictToFirstEntry = FALSE)
  density1 <- plotCohortTiming(timing1,
    plotType = "densityplot",
    facet = NULL,
    colour = c("cohort_name_reference", "cohort_name_comparator"),
    uniqueCombinations = TRUE
  )

  # expect_true(all(c("plot_id", "timing_label", "color_var", "x", "y", ".group") %in% colnames(density1$data)))
  expect_true(all(c("gg", "ggplot") %in% class(density1)))
  # expect_true(density1$labels$fill == "color_var")

  density2 <- plotCohortTiming(timing1,
    plotType = "densityplot",
    colour = c("cohort_name_comparator"),
    facet = c("cdm_name", "cohort_name_reference"),
    uniqueCombinations = FALSE
  )
  # expect_true(all(c("plot_id", "timing_label", "x", "y", ".group") %in% colnames(density2$data)))
  expect_true(all(c("gg", "ggplot") %in% class(density2)))
  # expect_null(density2$labels$fill)

  timing2 <- summariseCohortTiming(cdm$table, estimates = "density")
  density4 <- plotCohortTiming(timing2,
    plotType = "densityplot",
    facet = NULL,
    colour = c("cohort_name_reference", "cohort_name_comparator"),
    uniqueCombinations = TRUE
  )
  expect_true(all(c("gg", "ggplot") %in% class(density4)))
  # expect_true(all(is.na(density4$data$q50)))

  # strata
  cdm$table <- cdm$table |>
    PatientProfiles::addAge(ageGroup = list(c(0, 40), c(41, 150))) |>
    PatientProfiles::addSex() |>
    dplyr::compute(name = "table", temporary = FALSE) |>
    omopgenerics::newCohortTable()
  timing3 <- summariseCohortTiming(cdm$table,
    strata = list("age_group", c("age_group", "sex")),
    restrictToFirstEntry = FALSE
  )

  density3 <- plotCohortTiming(timing3,
    plotType = "densityplot",
    colour = c("age_group", "sex"),
    facet = c("cohort_name_reference", "cohort_name_comparator"),
    uniqueCombinations = FALSE
  )
  # expect_true(all(c("plot_id", "timing_label", "color_var", "x", "y", ".group") %in% colnames(density3$data)))
  expect_true(all(c("gg", "ggplot") %in% class(density3)))
  # expect_true(all(unique(density3$data$color_combined) %in% c("Overall", "0 to 40", "0 to 40 and female",
  #                                                        "41 to 150", "41 to 150 and female", "41 to 150 and male",
  #                                                        "0 to 40 and male")))
  # not sure why 41 to 150 does not have density
  mockDisconnect(cdm)
})

test_that("plotCohortTiming, density x axis", {
  cdm <- omopgenerics::cdmFromTables(
    tables = list(
      person = dplyr::tibble(
        person_id = 1L, gender_concept_id = 0L, year_of_birth = 2000L,
        month_of_birth = 1L, day_of_birth = 1L, birth_datetime = as.Date(NA_character_),
        race_concept_id = 0L, ethnicity_concept_id = 0L, location_id = 0L,
        provider_id = 0L, care_site_id = 0L, person_source_value = "",
        gender_source_value = "", gender_source_concept_id = 0L,
        race_source_value = "", race_source_concept_id = 0L,
        ethnicity_source_value = "", ethnicity_source_concept_id = 0L
      ),
      observation_period = dplyr::tibble(
        observation_period_id = 1L, person_id = 1L,
        observation_period_start_date = as.Date("2010-01-01"),
        observation_period_end_date = as.Date("2020-12-31"),
        period_type_concept_id = 0L
      )
    ),
    cdmName = "mock",
    cohortTables = list(cohort = dplyr::tibble(
      cohort_definition_id = c(1L, 1L, 1L, 2L, 2L, 2L),
      subject_id = 1L,
      cohort_start_date = as.Date(c(
        "2017-01-01", "2016-01-01", "2017-03-15", "2016-09-09", "2017-01-07",
        "2017-07-23"
      )),
      cohort_end_date = cohort_start_date
    ))
  )
  cdm <- CDMConnector::copyCdmTo(
    con = duckdb::dbConnect(duckdb::duckdb()), cdm = cdm, schema = "main")

  # first
  timing <- summariseCohortTiming(cdm$cohort)
  expect_no_error(p <- plotCohortTiming(timing, plotType = "densityplot"))
  xLimits <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x.range
  expect_true(xLimits[2] - xLimits[1] >= 5)
  expect_no_error(p <- plotCohortTiming(timing, plotType = "densityplot", timeScale = "years"))
  xLimits <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x.range
  expect_true(xLimits[2] - xLimits[1] >= 5/365)

  # all
  timing <- summariseCohortTiming(cdm$cohort, restrictToFirstEntry = FALSE)
  expect_no_error(p <- plotCohortTiming(timing, plotType = "densityplot"))
  xLimits <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x.range
  expect_true(xLimits[2] - xLimits[1] >= 5)
  expect_no_error(p <- plotCohortTiming(timing, plotType = "densityplot", timeScale = "years"))
  xLimits <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x.range
  expect_true(xLimits[2] - xLimits[1] >= 5/365)

  PatientProfiles::mockDisconnect(cdm = cdm)
})

