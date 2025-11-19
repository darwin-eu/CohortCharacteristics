test_that("test summariseCharacteristics", {
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
      "1990-04-19", "1992-04-19", "2010-12-14", "2000-05-26"
    )),
    blood_type = c("a", "a", "0", "0"),
    number_visits = c(0, 1, 5, 12) |> as.integer()
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
      cohort_definition_id = c(1, 2, 3) |> as.integer(),
      cohort_name = c("acetaminophen", "ibuprophen", "naloxone")
    ),
    cohortAttritionRef = NULL
  )

  expect_no_error(result <- summariseCharacteristics(
    cdm$dus_cohort,
    cohortIntersectFlag = list(
      "Medications" = list(
        targetCohortTable = "medication", window = c(-365, 0)
      ),
      "Comorbidities" = list(
        targetCohortTable = "comorbidities", window = c(-Inf, 0)
      )
    )
  ) |>
    suppress(minCellCount = 1))
  expect_true(inherits(result, "summarised_result"))
  expect_identical(
    result |>
      dplyr::filter(group_level == "exposed") |>
      dplyr::filter(variable_level == "Covid") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    2
  )
  expect_identical(
    result |>
      dplyr::filter(group_level == "exposed") |>
      dplyr::filter(variable_level == "Headache") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    1
  )
  expect_identical(
    result |>
      dplyr::filter(group_level == "exposed") |>
      dplyr::filter(variable_level == "Acetaminophen") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    2
  )
  expect_identical(
    result |>
      dplyr::filter(group_level == "exposed") |>
      dplyr::filter(variable_level == "Ibuprophen") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    0
  )
  expect_identical(
    result |>
      dplyr::filter(group_level == "exposed") |>
      dplyr::filter(variable_level == "Naloxone") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    0
  )
  expect_identical(
    result |>
      dplyr::filter(group_level == "unexposed") |>
      dplyr::filter(variable_level == "Covid") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    0
  )
  expect_identical(
    result |>
      dplyr::filter(group_level == "unexposed") |>
      dplyr::filter(variable_level == "Headache") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    1
  )
  expect_identical(
    result |>
      dplyr::filter(group_level == "unexposed") |>
      dplyr::filter(variable_level == "Acetaminophen") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    0
  )
  expect_identical(
    result |>
      dplyr::filter(group_level == "unexposed") |>
      dplyr::filter(variable_level == "Ibuprophen") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    0
  )
  expect_identical(
    result |>
      dplyr::filter(group_level == "unexposed") |>
      dplyr::filter(variable_level == "Naloxone") |>
      dplyr::filter(estimate_name == "count") |>
      dplyr::pull("estimate_value") |>
      as.numeric(),
    0
  )

  resDays <- result |>
    dplyr::filter(.data$variable_name == "Days in cohort")
  expect_identical(
    unique(resDays$estimate_value[
      resDays$group_level == "unexposed" & resDays$estimate_name != "sd"
    ]),
    "2"
  )
  resDays <- resDays |>
    dplyr::filter(.data$group_level == "exposed")
  days <- c(1L, 367L, 31L)
  expect_identical(
    resDays$estimate_value[resDays$estimate_name == "median"],
    as.character(median(days))
  )
  expect_identical(
    resDays$estimate_value[resDays$estimate_name == "q25"],
    as.character(quantile(days, 0.25))
  )
  expect_identical(
    resDays$estimate_value[resDays$estimate_name == "q75"],
    as.character(quantile(days, 0.75))
  )
  expect_identical(
    resDays$estimate_value[resDays$estimate_name == "min"],
    as.character(min(days))
  )
  expect_identical(
    resDays$estimate_value[resDays$estimate_name == "max"],
    as.character(max(days))
  )

  expect_no_error(result <- summariseCharacteristics(
    cdm$dus_cohort,
    cohortIntersectFlag = list(
      "Medications short" = list(
        targetCohortTable = "medication", window = list("short" = c(-30, 0))
      ),
      "Medications long" = list(
        targetCohortTable = "medication", window = list("long" = c(-365, 0))
      ),
      "Comorbidities" = list(
        targetCohortTable = "comorbidities", window = c(-Inf, 0)
      )
    )
  ) |>
    suppress(minCellCount = 1))
  expect_true(inherits(result, "summarised_result"))


  expect_identical(
    colnames(result |>
               dplyr::select(
                 -c("additional_name", "additional_level")
               )),
    colnames(result |>
               omopgenerics::splitAdditional())
  )


  expect_true(
  result |>
  dplyr::filter(variable_name == "Medications short") |>
      dplyr::tally() |>
      dplyr::pull() ==
      omopgenerics::settings(cdm$medication) |> nrow() * 4 # 2 group_level 4 estimate type
  )
  expect_true(
    result |>
      dplyr::filter(variable_name == "Medications long") |>
      dplyr::tally() |>
      dplyr::pull() ==
      omopgenerics::settings(cdm$medication) |> nrow() * 4 # 2 group_level 4 estimate type
  )
  expect_true(
    result |>
      dplyr::filter(variable_name %in% c("Medications short", "Medications long")) |>
      dplyr::tally() |>
      dplyr::pull() ==
      omopgenerics::settings(cdm$medication) |> nrow() * 8 # 2 group_level 4 estimate type 2 window
  )
  expect_true(
    result |>
      dplyr::filter(variable_name %in% c("Comorbidities")) |>
      dplyr::tally() |>
      dplyr::pull() ==
      omopgenerics::settings(cdm$comorbidities) |> nrow() * 4 # 2 group_level 4 estimate type
  )

  result_notables <- summariseCharacteristics(cdm$dus_cohort) |>
    suppress(minCellCount = 1)
  expect_true(inherits(result, "summarised_result"))

  # counts - both records and persons
  sc_person_record <- summariseCharacteristics(
    cdm$dus_cohort,
    counts = TRUE, demographics = FALSE
  )
  expect_true(nrow(sc_person_record |>
    dplyr::filter(variable_name == "Number records")) > 0)
  expect_true(nrow(sc_person_record |>
    dplyr::filter(variable_name == "Number subjects")) > 0)
  # counts - none
  sc_no_counts <- summariseCharacteristics(
    cdm$dus_cohort,
    counts = FALSE, demographics = TRUE
  )
  expect_true(nrow(sc_no_counts |>
    dplyr::filter(variable_name == "Number records")) == 0)
  expect_true(nrow(sc_no_counts |>
    dplyr::filter(variable_name == "Number subjects")) == 0)
  expect_error(summariseCharacteristics(
    cdm$dus_cohort,
    counts = "not an option", demographics = FALSE
  ))

  # no options chosen
  expect_no_error(empty <- summariseCharacteristics(
    cdm$dus_cohort,
    counts = FALSE, demographics = FALSE
  ))
  expect_equal(
    empty,
    omopgenerics::emptySummarisedResult(settings = dplyr::tibble(
      "result_id" = 1L,
      "package_name" = "CohortCharacteristics",
      "package_version" = as.character(utils::packageVersion(
        "CohortCharacteristics"
      )),
      "result_type" = "summarise_characteristics",
      "table_name" = "dus_cohort"
    ))
  )

  # demographics
  expect_no_error(result <- summariseCharacteristics(
    cdm$dus_cohort,
    demographics = TRUE,
    cohortIntersectFlag = list(
      "Medications" = list(
        targetCohortTable = "medication", window = c(-365, 0)
      )
    )
  ))
  expect_true(all(
    c(
      "Cohort start date", "Cohort end date", "Age", "Sex", "Prior observation",
      "Future observation"
    ) %in% result$variable_name
  ))
  expect_no_error(result <- summariseCharacteristics(
    cdm$dus_cohort,
    demographics = TRUE
  ))
  expect_true(all(
    c(
      "Cohort start date", "Cohort end date", "Age", "Sex", "Prior observation",
      "Future observation"
    ) %in% result$variable_name
  ))
  expect_no_error(result <- summariseCharacteristics(
    cdm$dus_cohort,
    demographics = FALSE,
    cohortIntersectFlag = list(
      "Medications" = list(
        targetCohortTable = "medication", window = c(-365, 0)
      )
    )
  ))
  expect_false(any(
    c(
      "Cohort start date", "Cohort end date", "Age", "Sex", "Prior observation",
      "Future observation"
    ) %in% result$variable_name
  ))

  # test other variables
  expect_no_error(
    result <- summariseCharacteristics(
      cdm$dus_cohort,
      cohortIntersectFlag = list(
        "Medications short" = list(
          targetCohortTable = "medication", window = list("short" = c(-30, 0))
        )
      ),
      otherVariables = c("blood_type", "number_visits"),
      estimates = list(blood_type = "count", number_visits = "mean")
    )
  )

  expect_true(all(c("Blood type", "Number visits") %in% result$variable_name))
  expect_true("mean" == unique(result$estimate_name[result$variable_name == "Number visits"]))
  expect_true("count" == unique(result$estimate_name[result$variable_name == "Blood type"]))

  expect_no_error(
    result <- summariseCharacteristics(
      cdm$dus_cohort,
      cohortIntersectFlag = list(
        "Medications short" = list(
          targetCohortTable = "medication", window = list("short" = c(-30, 0))
        )
      ),
      otherVariables = c("blood_type", "number_visits"),
      estimates = list(number_visits = "mean")
    )
  )

  expect_true("Blood type" %in% result$variable_name |> unique())
  expect_identical(
    sort(unique(result$estimate_name[result$variable_name == "Blood type"])),
    c("count", "percentage")
  )
  expect_true("Number visits" %in% result$variable_name |> unique())
  expect_true("mean" == unique(result$estimate_name[result$variable_name == "Number visits"]))

  expect_no_error(
    result <- summariseCharacteristics(
      cdm$dus_cohort,
      cohortIntersectFlag = list(
        "Medications short" = list(
          targetCohortTable = "medication", window = list("short" = c(-30, 0))
        )
      ),
      otherVariables = c("blood_type", "number_visits"),
      estimates = list(blood_type = "count", number_visits = "mean")
    )
  )

  expect_true(all(c("Blood type", "Number visits") %in% result$variable_name))
  expect_true("mean" == unique(result$estimate_name[result$variable_name == "Number visits"]))
  expect_true("count" == unique(result$estimate_name[result$variable_name == "Blood type"]))

  dropCreatedTables(cdm = cdm)
})

test_that("test empty cohort", {
  cdm <- mockCohortCharacteristics(numberIndividuals = 100) |>
    copyCdm()

  expect_no_error(
    cdm$cohort1 |> dplyr::filter(cohort_definition_id == 0) |>
      summariseCharacteristics(cohortIntersectFlag = list(
        "Medications" = list(
          targetCohortTable = "cohort2", window = c(-365, 0)
        ),
        "Comorbidities" = list(
          targetCohortTable = "cohort2", window = c(-Inf, 0)
        )
      ))
  )

  expect_no_error(
    res <- cdm$cohort1 |>
      summariseCharacteristics(cohortIntersectFlag = list(
        "Medications" = list(
          targetCohortTable = "cohort1", window = c(-365, 0), targetCohortId = 1
        ),
        "Comorbidities" = list(
          targetCohortTable = "cohort1", window = c(-Inf, 0)
        )
      ))
  )

  expect_true(
    res |>
      dplyr::filter(variable_name == "Medications") |>
      dplyr::pull("variable_level") |>
      unique() == "Cohort 1"
  )
  expect_true(all(
    res |>
      dplyr::filter(variable_name == "Comorbidities") |>
      dplyr::pull("variable_level") |>
      unique() |>
      sort() == c("Cohort 1", "Cohort 2", "Cohort 3")
  ))

  expect_no_error(
    x1 <- cdm$cohort1 |>
      summariseCharacteristics(tableIntersectFlag = list("Visits" = list(
        tableName = "visit_occurrence", window = c(-365, 0)
      )))
  )

  # expect_no_error(
  #   x3 <- cdm$cohort1 |>
  #     summariseCharacteristics(tableIntersect = list("Visits" = list(
  #       tableName = "visit_occurrence", value = "visit_concept_id",
  #       window = c(-Inf, Inf)
  #     )))
  # )

  dropCreatedTables(cdm = cdm)
})

test_that("test cohort id", {
  person <- dplyr::tibble(
    person_id = 1:3L,
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

  result <- summariseCharacteristics(
    cdm$dus_cohort,
    cohortId = 1,
    cohortIntersectFlag = list(
      "Medications" = list(
        targetCohortTable = "medication", window = c(-365, 0)
      ),
      "Comorbidities" = list(
        targetCohortTable = "comorbidities", window = c(-Inf, 0)
      )
    )
  )

  resultAll <- summariseCharacteristics(
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
  expect_true(inherits(result, "summarised_result"))
  expect_true(unique(result$group_level) == "exposed")
  expect_identical(
    resultAll |>
      dplyr::filter(group_level == "exposed") |>
      dplyr::arrange(.data$variable_name, .data$estimate_name, .data$estimate_value),
    result |>
      dplyr::arrange(.data$variable_name, .data$estimate_name, .data$estimate_value)
  )

  expect_error(
    summariseCharacteristics(
      cdm$dus_cohort,
      cohortId = c(1, 5),
      cohortIntersectFlag = list(
        "Medications" = list(
          targetCohortTable = "medication", window = c(-365, 0)
        ),
        "Comorbidities" = list(
          targetCohortTable = "comorbidities", window = c(-Inf, 0)
        )
      )
    )
  )

  expect_error(
    summariseCharacteristics(
      cdm$dus_cohort,
      cohortId = 5,
      cohortIntersectFlag = list(
        "Medications" = list(
          targetCohortTable = "medication", window = c(-365, 0)
        ),
        "Comorbidities" = list(
          targetCohortTable = "comorbidities", window = c(-Inf, 0)
        )
      )
    )
  )

  dropCreatedTables(cdm = cdm)
})

test_that("arguments tableIntersect", {
  person <- dplyr::tibble(
    person_id = 1:5L,
    gender_concept_id = as.integer(c(8507, 8532, 8532, 8507, 8507)),
    year_of_birth = as.integer(c(1985, 2000, 1962, 1999, 1979)),
    month_of_birth = as.integer(c(10, 5, 9, 2, 4)),
    day_of_birth = as.integer(c(30, 10, 24, 26, 25)),
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )
  dus_cohort <- dplyr::tibble(
    cohort_definition_id = as.integer(c(1, 1, 1, 2, 2, 2)),
    subject_id = as.integer(c(1, 1, 2, 3, 4, 5)),
    cohort_start_date = as.Date(c(
      "1990-04-19", "1991-04-19", "2010-11-14", "2000-05-25", "2010-01-01", "2009-09-09"
    )),
    cohort_end_date = as.Date(c(
      "1990-04-19", "1991-04-19", "2010-11-14", "2000-05-25", "2010-01-01", "2009-09-09"
    ))
  )

  observation_period <- dplyr::tibble(
    observation_period_id = 1:5L,
    person_id = 1:5L,
    observation_period_start_date = as.Date(c(
      "1985-01-01", "1989-04-29", "1974-12-03", "2003-01-01", "2005-01-01"
    )),
    observation_period_end_date = as.Date(c(
      "2011-03-04", "2022-03-14", "2023-07-10", "2024-12-31", "2024-12-31"
    )),
    period_type_concept_id = 0L
  )

  visit_occurrence <- dplyr::tibble(
    visit_occurrence_id = 1:10L,
    person_id = as.integer(c(1, 1, 1, 1, 5, 2, 2, 4, 5, 4)),
    visit_start_date = as.Date(c(
      "2009-01-01", "2011-01-02", "1994-12-03", "2013-01-01", "2005-01-01", "2008-08-08", "2009-09-09", "2010-10-10", "2011-11-11", "2008-09-01"
    )),
    visit_concept_id = 0L,
    visit_end_date = visit_start_date,
    visit_type_concept_id = 0L
  )

  cdm <- mockCohortCharacteristics(
    dus_cohort = dus_cohort,
    person = person,
    observation_period = observation_period,
    visit_occurrence = visit_occurrence
  ) |>
    copyCdm()

  cdm$dus_cohort <- cdm$dus_cohort |>
    omopgenerics::newCohortTable(
      cohortSetRef = dplyr::tibble(cohort_definition_id = c(1L, 2L), cohort_name = c("exposed", "unexposed"))
    )

  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$dus_cohort,
      ageGroup = list(c(0, 50), c(51, 150)),
      tableIntersectCount = list(
        "Number visits anytime before" = list(
          tableName = "visit_occurrence", window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Number visits anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_true(
    "0 to 50" %in%
      (results %>% dplyr::pull("variable_level"))
  )

  expect_true(
    "51 to 150" %in%
      (results %>% dplyr::pull("variable_level"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "exposed",
        variable_name == "Number visits anytime before",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    0
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "unexposed",
        variable_name == "Number visits anytime before",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    0
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "exposed",
        variable_name == "Number visits anytime before",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    2
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "unexposed",
        variable_name == "Number visits anytime before",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    1
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "exposed",
        variable_name == "Number visits anytime before",
        estimate_name == "median"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    0
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "unexposed",
        variable_name == "Number visits anytime before",
        estimate_name == "median"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    1
  )

  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$dus_cohort,
      ageGroup = list(c(0, 20), c(21, 150)),
      tableIntersectFlag = list(
        "Flag visits anytime before" = list(
          tableName = "visit_occurrence", window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Flag visits anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_true(
    "0 to 20" %in%
      (results %>% dplyr::pull("variable_level"))
  )

  expect_true(
    "21 to 150" %in%
      (results %>% dplyr::pull("variable_level"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "exposed",
        variable_name == "Flag visits anytime before",
        estimate_name == "count"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    1
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "unexposed",
        variable_name == "Flag visits anytime before",
        estimate_name == "count"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    2
  )

  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$dus_cohort,
      tableIntersectDate = list(
        "Date visits anytime before" = list(
          tableName = "visit_occurrence",
          order = "last",
          window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Date visits anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "exposed",
        variable_name == "Date visits anytime before",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.Date(),
    as.Date("2009-09-09")
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "unexposed",
        variable_name == "Date visits anytime before",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.Date(),
    as.Date("2005-01-01")
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "exposed",
        variable_name == "Date visits anytime before",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.Date(),
    as.Date("2009-09-09")
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "unexposed",
        variable_name == "Date visits anytime before",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.Date(),
    as.Date("2008-09-01")
  )

  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$dus_cohort,
      tableIntersectDays = list(
        "Days visits anytime after" = list(
          tableName = "visit_occurrence",
          order = "first",
          window = c(1, Inf)
        )
      )
    )
  )

  expect_true(
    "Days visits anytime after" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "exposed",
        variable_name == "Days visits anytime after",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    as.numeric(as.Date("1994-12-03") - as.Date("1991-04-19"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "unexposed",
        variable_name == "Days visits anytime after",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    as.numeric(as.Date("2010-10-10") - as.Date("2010-01-01"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "exposed",
        variable_name == "Days visits anytime after",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    as.numeric(as.Date("1994-12-03") - as.Date("1990-04-19"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        group_level == "unexposed",
        variable_name == "Days visits anytime after",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    as.numeric(as.Date("2011-11-11") - as.Date("2009-09-09"))
  )

  dropCreatedTables(cdm = cdm)
})

test_that("arguments cohortIntersect", {
  dus_cohort <- dplyr::tibble(
    cohort_definition_id = c(1, 1, 1, 1, 1, 1) |> as.integer(),
    subject_id = c(1, 1, 2, 3, 2, 3) |> as.integer(),
    cohort_start_date = as.Date(c(
      "1990-04-19", "1991-04-19", "2010-11-14", "2000-05-25", "2010-01-01", "2009-09-09"
    )),
    cohort_end_date = as.Date(c(
      "1990-04-19", "1991-04-19", "2010-11-14", "2000-05-25", "2010-01-01", "2009-09-09"
    ))
  )

  cohort1 <- dplyr::tibble(
    cohort_definition_id = c(1, 1, 1, 1, 1, 1) |> as.integer(),
    subject_id = c(3, 2, 1, 1, 2, 3) |> as.integer(),
    cohort_start_date = as.Date(c(
      "2001-04-20", "1992-04-19", "2009-11-14", "1999-05-26", "2009-01-01", "2010-09-10"
    )),
    cohort_end_date = as.Date(c(
      "2001-04-20", "1992-04-19", "2009-11-14", "1999-05-26", "2009-01-01", "2010-09-10"
    ))
  )

  observation_period <- dplyr::tibble(
    observation_period_id = c(1, 2, 3, 4, 5) |> as.integer(),
    person_id = c(1, 2, 3, 4, 5) |> as.integer(),
    observation_period_start_date = as.Date(c(
      "1985-01-01", "1989-04-29", "1974-12-03", "1983-01-01", "1985-01-01"
    )),
    observation_period_end_date = as.Date(c(
      "2021-03-04", "2022-03-14", "2023-07-10", "2024-12-31", "2024-12-31"
    )),
    period_type_concept_id = 0L
  )

  cdm <- mockCohortCharacteristics(
    dus_cohort = dus_cohort,
    cohort1 = cohort1,
    cohort2 = cohort1,
    observation_period = observation_period
  ) |>
    copyCdm()

  ### intersect count
  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$dus_cohort,
      cohortIntersectCount = list(
        "Cohort 1 anytime before" = list(
          targetCohortTable = "cohort1", window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Cohort 1 anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Cohort 1 anytime before",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    0
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Cohort 1 anytime before",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    2
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Cohort 1 anytime before",
        estimate_name == "median"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    0.5
  )

  ## intersect flag
  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$dus_cohort,
      cohortIntersectFlag = list(
        "Cohort 1 (flag) anytime before" = list(
          targetCohortTable = "cohort1", window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Cohort 1 (flag) anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Cohort 1 (flag) anytime before",
        estimate_name == "count"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    3
  )

  ## intersect date
  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$dus_cohort,
      cohortIntersectDate = list(
        "Date cohort 1 anytime before" = list(
          targetCohortTable = "cohort1",
          order = "last",
          window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Date cohort 1 anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Date cohort 1 anytime before",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.Date(),
    as.Date("2001-04-20")
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Date cohort 1 anytime before",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.Date(),
    as.Date("2009-01-01")
  )

  ## Intersect Days
  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$dus_cohort,
      cohortIntersectDays = list(
        "Days cohort 1 anytime after" = list(
          targetCohortTable = "cohort1",
          order = "first",
          window = c(1, Inf)
        )
      )
    )
  )

  expect_true(
    "Days cohort 1 anytime after" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Days cohort 1 anytime after",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    as.numeric(as.Date("2001-04-20") - as.Date("2000-05-25"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Days cohort 1 anytime after",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    as.numeric(as.Date("1999-05-26") - as.Date("1990-04-19"))
  )

  dropCreatedTables(cdm = cdm)
})

test_that("arguments conceptIntersect", {
  skip_on_cran()

  cdm <- omock::mockCdmFromDataset(datasetName = "GiBleed", source = "local") |>
    copyCdm()

  # create a cohort
  cdm <- CDMConnector::generateConceptCohortSet(
    cdm = cdm,
    conceptSet = list("sinusitis" = c(4294548L, 40481087L, 257012L)),
    name = "my_cohort"
  )

  codelist <- list(
    "statin" = cdm$concept |>
      dplyr::filter(grepl("statin", concept_name, ignore.case = TRUE)) |>
      dplyr::pull("concept_id"),
    "serum_measurement" = cdm$concept |>
      dplyr::filter(grepl("serum", concept_name, ignore.case = TRUE)) |>
      dplyr::pull("concept_id"),
    "allergy" = cdm$concept |>
      dplyr::filter(grepl("allergy", concept_name, ignore.case = TRUE)) |>
      dplyr::pull("concept_id"),
    "bypass" = cdm$concept |>
      dplyr::filter(grepl("bypass", concept_name, ignore.case = TRUE)) |>
      dplyr::pull("concept_id"),
    "laceration" = cdm$concept |>
      dplyr::filter(grepl("laceration", concept_name, ignore.case = TRUE)) |>
      dplyr::pull("concept_id")
  )

  cdm <- CDMConnector::generateConceptCohortSet(
    cdm = cdm, conceptSet = list("sinusitis" = c(4294548L, 40481087L, 257012L)),
    name = "sinusitis"
  )

  ### intersect count
  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$sinusitis,
      conceptIntersectCount = list(
        "Codelist count anytime before" = list(
          conceptSet = codelist, window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Codelist count anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Codelist count anytime before",
        estimate_name == "min",
        variable_level == "Allergy"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    0
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Codelist count anytime before",
        estimate_name == "max",
        variable_level == "Serum measurement"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.numeric(),
    59
  )

  ## intersect flag
  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$sinusitis,
      conceptIntersectFlag = list(
        "Codelist flag anytime before" = list(
          conceptSet = codelist, window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Codelist flag anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Codelist flag anytime before",
        estimate_name == "count"
      ) %>%
      dplyr::filter(estimate_value > 0) %>%
      dplyr::tally() %>%
      dplyr::pull("n") %>%
      as.numeric(),
    4
  )

  ## intersect date
  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$sinusitis,
      conceptIntersectDate = list(
        "Codelist date anytime before" = list(
          conceptSet = codelist,
          order = "last",
          window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Codelist date anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Codelist date anytime before",
        estimate_name == "min"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.Date() %>%
      na.omit() |>
      length() %>%
      as.numeric(),
    4
  )

  expect_identical(
    results %>%
      dplyr::filter(
        variable_name == "Codelist date anytime before",
        estimate_name == "max"
      ) %>%
      dplyr::pull("estimate_value") %>%
      as.Date() %>%
      na.omit() |>
      length() %>%
      as.numeric(),
    4
  )

  ## Intersect Days
  expect_no_error(
    results <- summariseCharacteristics(
      cohort = cdm$sinusitis,
      conceptIntersectDays = list(
        "Codelist days anytime before" = list(
          conceptSet = codelist,
          order = "last",
          window = c(-Inf, -1)
        )
      )
    )
  )

  expect_true(
    "Codelist days anytime before" %in%
      (results %>% dplyr::pull("variable_name"))
  )

  expect_true(all(
    results %>%
      dplyr::filter(
        variable_name == "Codelist days anytime before",
        estimate_name == "min"
      ) %>%
      dplyr::select("estimate_value") %>%
      dplyr::mutate(estimate_value = as.integer(estimate_value)) %>%
      dplyr::pull("estimate_value") |>
      na.omit() %>%
      as.numeric() < 0
  ))

  expect_true(all(
    results %>%
      dplyr::filter(
        variable_name == "Codelist days anytime before",
        estimate_name == "max"
      ) %>%
      dplyr::select("estimate_value") %>%
      dplyr::mutate(estimate_value = as.integer(estimate_value)) %>%
      dplyr::pull("estimate_value") |>
      na.omit() %>%
      as.numeric() < 0
  ))

  # expect time between cohorts
  results <- summariseCharacteristics(cohort = cdm$sinusitis)
  expect_true("Days to next record" %in% results$variable_name)

  cdm <- CDMConnector::generateConceptCohortSet(
    cdm = cdm, conceptSet = list("sinusitis" = c(4294548L, 40481087L, 257012L)),
    name = "sinusitis",
    end = 0,
    limit = "all"
  )
  results <- summariseCharacteristics(cohort = cdm$sinusitis)
  expect_true("Days to next record" %in% results$variable_name)
  expect_no_error(tableCharacteristics(result = results))

  dropCreatedTables(cdm = cdm)
})

test_that("empty input cohort contains name issue #170", {
  cdm <- mockCohortCharacteristics(numberIndividuals = 10) |>
    copyCdm()

  cdm <- omopgenerics::emptyCohortTable(cdm = cdm, name = "cohort1")
  cdm$cohort1 <- cdm$cohort1 |>
    omopgenerics::newCohortTable(
      cohortSetRef = dplyr::tibble(
        cohort_definition_id = 1:3L, cohort_name = c("c1", "c2", "c3")
      )
    )

  expect_no_error(res <- cdm$cohort1 |> summariseCharacteristics())
  expect_true(nrow(res) == 6)
  expect_true(unique(res$estimate_value) == "0")
  attr(res, "settings") <- NULL
  expect_equal(
    res |>
      dplyr::select("group_level", "variable_name") |>
      dplyr::as_tibble(),
    tidyr::expand_grid(
      "group_level" = omopgenerics::settings(cdm$cohort1)$cohort_name,
      "variable_name" = c("Number subjects", "Number records")
    )
  )

  dropCreatedTables(cdm = cdm)
})

test_that("output is always the same", {
  skip_on_cran()
  set.seed(123456)
  cdm1 <- omock::mockCdmReference() |>
    omock::mockPerson(nPerson = 100) |>
    omock::mockObservationPeriod() |>
    omock::mockConditionOccurrence(recordPerson = 3) |>
    omock::mockDrugExposure(recordPerson = 4.5) |>
    omock::mockCohort(
      numberCohorts = 3, cohortName = c("covid", "tb", "asthma")
    ) |>
    copyCdm()

  src <- CDMConnector::dbSource(
    con = duckdb::dbConnect(drv = duckdb::duckdb()),
    writeSchema = "main"
  )
  cdm2 <- omopgenerics::insertCdmTo(cdm = dplyr::collect(cdm1), to = src)

  result1 <- summariseCharacteristics(cdm1$cohort) |>
    dplyr::mutate(estimate_value = dplyr::if_else(
      .data$estimate_type == "numeric",
      as.character(round(suppressWarnings(as.numeric(.data$estimate_value)), 3)),
      .data$estimate_value
    ))

  result2 <- summariseCharacteristics(cdm2$cohort) |>
    dplyr::mutate(estimate_value = dplyr::if_else(
      .data$estimate_type == "numeric",
      as.character(round(suppressWarnings(as.numeric(.data$estimate_value)), 3)),
      .data$estimate_value
    ))

  expect_identical(result1, result2)

  dropCreatedTables(cdm = cdm1)
  dropCreatedTables(cdm = cdm2)
})

test_that("arrange ageGroup", {
  person <- dplyr::tibble(
    person_id = c(1L, 2L),
    gender_concept_id = c(8507L, 8532L),
    year_of_birth = c(1950, 2000),
    month_of_birth = 1L,
    day_of_birth = 1L,
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )
  my_cohort <- dplyr::tibble(
    cohort_definition_id = 1L,
    subject_id = c(1L, 2L),
    cohort_start_date = as.Date("2020-01-01"),
    cohort_end_date = as.Date("2020-01-01")
  )
  observation_period <- dplyr::tibble(
    observation_period_id = c(1L, 2L),
    person_id = c(1L, 2L),
    observation_period_start_date = as.Date("2010-01-01"),
    observation_period_end_date = as.Date("2020-01-01"),
    period_type_concept_id = 0L
  )

  cdm <- mockCohortCharacteristics(
    person = person,
    my_cohort = my_cohort,
    observation_period = observation_period
  ) |>
    copyCdm()

  # ascendant order
  ageGroup <- list("0 to 49" = c(0, 49), "50 or older" = c(50, Inf))
  res1 <- cdm$my_cohort |>
    summariseCharacteristics(demographics = FALSE, ageGroup = ageGroup)
  expect_identical(
    res1$variable_level |> unique() |> purrr::keep(\(x) !is.na(x)),
    sort(names(ageGroup))
  )

  # descending order
  ageGroup <- list("50 or older" = c(50, Inf), "0 to 49" = c(0, 49))
  res2 <- cdm$my_cohort |>
    summariseCharacteristics(demographics = FALSE, ageGroup = ageGroup)
  expect_identical(
    res2$variable_level |> unique() |> purrr::keep(\(x) !is.na(x)),
    names(ageGroup)
  )

  # multiple age groups
  ageGroup <- list(
    "Age group 1" = list("0 to 49" = c(0, 49), "50 or older" = c(50, Inf)),
    "Age group 2" = list("50 or older" = c(50, Inf), "0 to 49" = c(0, 49))
  )
  res3 <- cdm$my_cohort |>
    summariseCharacteristics(demographics = FALSE, ageGroup = ageGroup)

  expect_equal(
    res3 |>
      dplyr::filter(!grepl("Number", .data$variable_name)) |>
      dplyr::select("variable_name", "variable_level") |>
      dplyr::distinct(),
    dplyr::tibble(
      variable_name = names(ageGroup)[1],
      variable_level = names(ageGroup[[1]])
    ) |>
      dplyr::union_all(dplyr::tibble(
        variable_name = names(ageGroup)[2],
        variable_level = names(ageGroup[[2]])
      )),
    ignore_attr = TRUE
  )

  # all age groups are present
  ageGroup <- list("G1" = c(0, 49), "G2" = c(50, 99), "G3" = c(100, 150))
  res4 <- cdm$my_cohort |>
    summariseCharacteristics(demographics = FALSE, ageGroup = ageGroup)
  expect_identical(
    res4 |>
      dplyr::filter(.data$variable_name == "Age group") |>
      dplyr::pull("variable_level") |>
      unique(),
    names(ageGroup)
  )

  dropCreatedTables(cdm = cdm)
})

test_that("test estimates", {
  skip_on_cran()
  cdm <- mockCohortCharacteristics() |>
    copyCdm()

  # age_group density
  result <- cdm$cohort1 |>
    summariseCharacteristics(estimates = list(age = "density"))
  estimatesAge <- result |>
    dplyr::filter(variable_name == "Age") |>
    dplyr::distinct(.data$estimate_name) |>
    dplyr::pull() |>
    sort()
  expect_identical(estimatesAge, c("density_x", "density_y"))

  resultNormal <- cdm$cohort1 |>
    summariseCharacteristics() |>
    dplyr::filter(.data$variable_name != "Age")
  expect_equal(
    resultNormal,
    result |> dplyr::filter(.data$variable_name != "Age"),
    ignore_attr = TRUE
  )

  # change default of all dates
  estimatesDate <- cdm$cohort1 |>
    summariseCharacteristics(estimates = list(date = "median")) |>
    dplyr::filter(.data$estimate_type == "date") |>
    dplyr::distinct(.data$estimate_name) |>
    dplyr::pull()
  expect_identical(estimatesDate, "median")

  # ignored field
  expect_warning(
    summariseCharacteristics(cdm$cohort1, estimates = list(not_present = "min"))
  )

  dropCreatedTables(cdm = cdm)
})

test_that("weights in summariseCharacteristics", {
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
      "1990-04-19", "1992-04-19", "2010-12-14", "2000-05-26"
    )),
    blood_type = c("a", "a", "0", "0"),
    number_visits = c(0, 1, 5, 12) |> as.integer(),
    my_weights_column = c(1.3, 0.25, 0.75, 0.15)
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
    medication = medication,
    observation_period = observation_period
  ) |>
    copyCdm()

  expect_no_error(
    result <- cdm$dus_cohort |>
      summariseCharacteristics(
        cohortIntersectFlag = list("Medication prior year" = list(
          targetCohortTable = "medication", window = c(-365, -1)
        ))
      ) |>
      omopgenerics::tidy()
  )
  expect_no_error(
    resultW <- cdm$dus_cohort |>
      summariseCharacteristics(
        cohortIntersectFlag = list("Medication prior year" = list(
          targetCohortTable = "medication", window = c(-365, -1)
        )),
        weights = "my_weights_column"
      ) |>
      omopgenerics::tidy()
  )

  # cohort 2 has only one individual so the expected results must be the same
  expect_identical(
    result$mean[result$cohort_name == "cohort_2" & result$variable_name == "Age"],
    resultW$mean[resultW$cohort_name == "cohort_2" & resultW$variable_name == "Age"]
  )
  expect_identical(
    result$mean[result$cohort_name == "cohort_2" & result$variable_name == "Days in cohort"],
    resultW$mean[resultW$cohort_name == "cohort_2" & resultW$variable_name == "Days in cohort"]
  )
  expect_identical(
    result$mean[result$cohort_name == "cohort_2" & result$variable_name == "Future observation"],
    resultW$mean[resultW$cohort_name == "cohort_2" & resultW$variable_name == "Future observation"]
  )
  expect_identical(
    result$percentage[result$cohort_name == "cohort_2" & result$variable_name == "Sex" & result$variable_level == "Female"],
    resultW$percentage[resultW$cohort_name == "cohort_2" & resultW$variable_name == "Sex" & resultW$variable_level == "Female"]
  )

  # cohort 1 has 3 individuala so the expected results must be different
  expect_identical(
    round((4 * 1.3 + 5 * 0.25 + 21 * 0.75) / (1.3 + 0.25 + 0.75), 3),
    round(resultW$mean[resultW$cohort_name == "cohort_1" & resultW$variable_name == "Age"], 3)
  )
  expect_identical(
    round((1 * 1.3 + 367 * 0.25 + 31 * 0.75) / (1.3 + 0.25 + 0.75), 3),
    round(resultW$mean[resultW$cohort_name == "cohort_1" & resultW$variable_name == "Days in cohort"], 3)
  )
  expect_identical(
    round((7624 * 1.3 + 7259 * 0.25 + 4138 * 0.75) / (1.3 + 0.25 + 0.75), 3),
    round(resultW$mean[resultW$cohort_name == "cohort_1" & resultW$variable_name == "Future observation"], 3)
  )
  expect_identical(
    round(100 * 0.75 / (1.3 + 0.25 + 0.75), 3),
    round(resultW$percentage[resultW$cohort_name == "cohort_1" & resultW$variable_name == "Sex" & resultW$variable_level == "Female"], 3)
  )

  dropCreatedTables(cdm = cdm)
})
