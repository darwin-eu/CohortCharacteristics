test_that("test plot", {
  skip_on_cran()
  person <- dplyr::tibble(
    person_id = 1:3L,
    gender_concept_id = as.integer(c(8507, 8532, 8532)),
    year_of_birth = as.integer(c(1985, 2000, 1962)),
    month_of_birth = as.integer(c(10, 5, 9)),
    day_of_birth = as.integer(c(30, 10, 24)),
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )
  dus_cohort <- dplyr::tibble(
    cohort_definition_id = as.integer(c(1, 1, 1, 2)),
    subject_id = as.integer(c(1, 1, 2, 3)),
    cohort_start_date = as.Date(c(
      "1990-04-19", "1991-04-19", "2010-11-14", "2000-05-25"
    )),
    cohort_end_date = as.Date(c(
      "1990-04-19", "1991-04-19", "2010-11-14", "2000-05-25"
    ))
  )
  comorbidities <- dplyr::tibble(
    cohort_definition_id = as.integer(c(1, 2, 2, 1)),
    subject_id = as.integer(c(1, 1, 3, 3)),
    cohort_start_date = as.Date(c(
      "1990-01-01", "1990-06-01", "2000-01-01", "2000-06-01"
    )),
    cohort_end_date = as.Date(c(
      "1990-01-01", "1990-06-01", "2000-01-01", "2000-06-01"
    ))
  )
  medication <- dplyr::tibble(
    cohort_definition_id = as.integer(c(1, 1, 2, 1)),
    subject_id = as.integer(c(1, 1, 2, 3)),
    cohort_start_date = as.Date(c(
      "1990-02-01", "1990-08-01", "2009-01-01", "1995-06-01"
    )),
    cohort_end_date = as.Date(c(
      "1990-02-01", "1990-08-01", "2009-01-01", "1995-06-01"
    ))
  )
  observation_period <- dplyr::tibble(
    observation_period_id = 1:3L,
    person_id = 1:3L,
    observation_period_start_date = as.Date(c(
      "1985-01-01", "1989-04-29", "1974-12-03"
    )),
    observation_period_end_date = as.Date(c(
      "2011-03-04", "2022-03-14", "2023-07-10"
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
      cohort_definition_id = c(1L, 2L), cohort_name = c("exposed", "unexposed")
    )
  )
  cdm$comorbidities <- omopgenerics::newCohortTable(
    table = cdm$comorbidities, cohortSetRef = dplyr::tibble(
      cohort_definition_id = c(1L, 2L), cohort_name = c("covid", "headache")
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
  test_data <- summariseCharacteristics(
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

  # barplot
  plot <- plotCharacteristics(
    result = test_data |>
      dplyr::filter(
        variable_name == "Medications",
        estimate_type == "percentage"
      ),
    plotType = "barplot",
    facet = c("cohort_name"),
    colour = c("variable_name", "variable_level")
  )


  expect_true(ggplot2::is_ggplot(plot))

  # boxplot
  plot2 <- plotCharacteristics(
    result = test_data |>
      dplyr::filter(variable_name == "Age"),
    plotType = "boxplot",
    facet = "variable_name",
    colour = c("cohort_name"),
    style = "darwin"
  )

  expect_true(ggplot2::is_ggplot(plot2))

  expect_no_error(plotCharacteristics(
    result = test_data |>
      dplyr::filter(variable_name == "Age"),
    plotType = "boxplot"
  ))

  expect_no_error(plotCharacteristics(
    result = test_data |>
      dplyr::filter(variable_name == "Age"),
    plotType = "boxplot",
    style  = "darwin"
  ))

  expect_no_error(plotCharacteristics(
    result = test_data |>
      dplyr::filter(variable_name == "Age"),
    plotType = "boxplot"
  ))

  expect_no_error(plotCharacteristics(
    result = test_data |>
      dplyr::filter(variable_name == "Age"),
    plotType = "barplot"
  ))

  expect_no_error(plotCharacteristics(
    result = test_data |>
      dplyr::filter(variable_name == "Age"),
    plotType = "scatterplot",
    style = "default"
  ))

  expect_no_error(plotCharacteristics(
    result = test_data |>
      dplyr::filter(variable_name == "Age"),
    plotType = "scatterplot"
  ))

  #densityplot
  test_data <- summariseCharacteristics(
    cdm$dus_cohort,
    estimates = list(age = c("density"))
  )

  expect_no_error(
    test_data |> dplyr::filter(variable_name %in%  c("Age")) |>
      plotCharacteristics(plotType = "densityplot")
  )

  expect_true(ggplot2::is_ggplot(test_data |> dplyr::filter(variable_name %in%  c("Age")) |>
                                       plotCharacteristics(plotType = "densityplot")))

  dropCreatedTables(cdm = cdm)
})

test_that("plotCharacteristics", {
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
    observation_period = observation_period
  ) |>
    copyCdm()

  result1 <- summariseCharacteristics(
    cdm$dus_cohort,
    demographics = TRUE,
    ageGroup = list(c(0, 40), c(41, 150))
  )

  gg1 <- plotCharacteristics(result1 |>
    dplyr::filter(variable_name ==
      "Prior observation"))
  expect_true(ggplot2::is_ggplot(gg1))

  gg2 <- plotCharacteristics(
    result1 |>
      dplyr::filter(variable_name ==
        "Age"),
    plotType = "boxplot",
    colour = "variable_name"
  )
  expect_true(ggplot2::is_ggplot(gg2))

  dropCreatedTables(cdm = cdm)
})
