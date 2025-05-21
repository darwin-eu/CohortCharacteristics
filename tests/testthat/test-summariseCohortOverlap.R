test_that("summariseCohortOverlap", {
  person <- dplyr::tibble(
    person_id = c(1:20, 199) |> as.integer(),
    gender_concept_id = 8532L,
    year_of_birth = sample(1950:2000L, size = 21, replace = T),
    month_of_birth = sample(1:12L, size = 21, replace = T),
    day_of_birth = sample(1:28L, size = 21, replace = T),
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )

  table <- dplyr::tibble(
    cohort_definition_id = c(rep(1, 15), rep(2, 10), rep(3, 15), rep(4, 5), 5) |>
      as.integer(),
    subject_id = c(
      20, 5, 10, 12, 4, 15, 2, 1, 5, 10, 5, 8, 13, 4, 10,
      6, 18, 5, 1, 20, 14, 13, 8, 17, 3,
      16, 15, 20, 17, 3, 14, 6, 11, 8, 7, 20, 19, 5, 2, 18,
      5, 12, 3, 14, 13, 199
    ) |> as.integer(),
    cohort_start_date = as.Date(c(
      rep("2000-01-01", 5), rep("2010-09-05", 5), rep("2006-05-01", 5),
      rep("2003-03-31", 5), rep("2008-07-02", 5), rep("2000-01-01", 5),
      rep("2012-09-05", 5), rep("1996-05-01", 5), rep("1989-03-31", 5), "1989-03-31"
    )),
    cohort_end_date = as.Date(c(
      rep("2000-01-01", 5), rep("2010-09-05", 5), rep("2006-05-01", 5),
      rep("2003-03-31", 5), rep("2008-07-02", 5), rep("2000-01-01", 5),
      rep("2012-09-05", 5), rep("1996-05-01", 5), rep("1989-03-31", 5), "1989-03-31"
    ))
  )

  obs <- dplyr::tibble(
    observation_period_id = c(1:20, 199) |> as.integer(),
    person_id = c(1:20, 199) |> as.integer(),
    observation_period_start_date = as.Date("1930-01-01"),
    observation_period_end_date = as.Date("2025-01-01"),
    period_type_concept_id = 0L
  )

  cdm <- mockCohortCharacteristics(
    con = connection(), writeSchema = writeSchema(),
    person = person, observation_period = obs, table = table
  )

  overlap1 <- summariseCohortOverlap(cdm$table)
  expect_equal(
    omopgenerics::resultColumns("summarised_result"),
    colnames(overlap1)
  )
  expect_equal(
    overlap1$group_name |> unique(),
    "cohort_name_reference &&& cohort_name_comparator"
  )
  expect_true(nrow(overlap1) == 5 * 4 * 6)
  expect_equal(unique(overlap1$strata_name), "overall")
  expect_equal(unique(overlap1$strata_level), "overall")
  expect_equal(unique(overlap1$additional_name), "overall")
  expect_equal(unique(overlap1$additional_level), "overall")
  expect_true(all(c("count", "percentage") %in% unique(overlap1$estimate_name)))

  # check some numbers
  id1 <- c(1, 2, 3, 4, 5)
  id2 <- c(1, 2, 3, 4, 5)
  set <- omopgenerics::settings(cdm$table) |>
    dplyr::select("cohort_name", "cohort_definition_id")
  for (i in id1) {
    for (j in id2) {
      if (i != j) {
        x <- cdm$table |>
          dplyr::filter(.data$cohort_definition_id %in% .env$i) |>
          dplyr::distinct(.data$subject_id) |>
          dplyr::inner_join(
            cdm$table |>
              dplyr::filter(.data$cohort_definition_id %in% .env$j) |>
              dplyr::distinct(.data$subject_id),
            by = "subject_id"
          ) |>
          dplyr::tally() |>
          dplyr::pull() |>
          as.character()
        y <- overlap1 |>
          omopgenerics::filterGroup(
            cohort_name_reference == !!set$cohort_name[set$cohort_definition_id == i],
            cohort_name_comparator == !!set$cohort_name[set$cohort_definition_id == j]
          ) |>
          dplyr::filter(variable_name == "In both cohorts", estimate_type == "integer") |>
          dplyr::pull("estimate_value")
        expect_identical(x, y)
      }
    }
    count1 <- overlap1 |>
      omopgenerics::filterGroup(
        cohort_name_reference == !!set$cohort_name[set$cohort_definition_id == i]
      ) |>
      dplyr::filter(estimate_type == "integer" & .data$variable_name != "Only in comparator cohort") |>
      dplyr::mutate(estimate_value = as.integer(.data$estimate_value)) |>
      dplyr::group_by(.data$group_level) |>
      dplyr::summarise(n = sum(.data$estimate_value)) |>
      dplyr::pull("n") |>
      unique()
    count2 <- omopgenerics::cohortCount(cdm$table) |>
      dplyr::filter(.data$cohort_definition_id == i) |>
      dplyr::pull("number_subjects") |>
      as.integer()
    count3 <- overlap1 |>
      omopgenerics::filterGroup(
        cohort_name_comparator == !!set$cohort_name[set$cohort_definition_id == i]
      ) |>
      dplyr::filter(estimate_type == "integer" & .data$variable_name != "Only in reference cohort") |>
      dplyr::mutate(estimate_value = as.integer(.data$estimate_value)) |>
      dplyr::group_by(.data$group_level) |>
      dplyr::summarise(n = sum(.data$estimate_value)) |>
      dplyr::pull("n") |>
      unique()
    expect_identical(count1, count2)
    expect_identical(count1, count3)
  }

  # strata and cohortID ----
  overlap2 <- summariseCohortOverlap(cdm$table,
    cohortId = 1:2
  )
  expect_true(nrow(overlap2) == 2 * 6)
  expect_true(all(
    c("cohort_2 &&& cohort_1", "cohort_1 &&& cohort_2") %in%
      unique(overlap2$group_level)
  ))

  cdm$table <- cdm$table |>
    PatientProfiles::addAge(ageGroup = list(c(0, 40), c(41, 100))) |>
    PatientProfiles::addSex() |>
    dplyr::compute(name = "table", temporary = FALSE) |>
    omopgenerics::newCohortTable()

  s <- cdm$table |>
    dplyr::filter(cohort_definition_id %in% 1:2) |>
    dplyr::distinct(age_group, sex)
  s1 <- nrow(s |> dplyr::collect())
  s2 <- nrow(s |> dplyr::distinct(age_group) |> dplyr::collect())

  overlap3 <- summariseCohortOverlap(cdm$table,
    cohortId = 1:2,
    strata = list("age_group", c("age_group", "sex"))
  )
  expect_true(all(unique(overlap3$group_level) %in%
    unique(overlap1$group_level)))
  expect_true(all(c("overall", "age_group", "age_group &&& sex") %in%
    unique(overlap3$strata_name)))
  expect_true(nrow(overlap3) == 2 * 6 + 2 * 6 * s1 + 2 * 6 * s2)

  mockDisconnect(cdm)

  # use pipe
  cdm <- mockCohortCharacteristics(
    con = connection(), writeSchema = writeSchema(),
    person = person, observation_period = obs, table = table
  )
  overlap4 <- cdm$table |>
    PatientProfiles::addAge(ageGroup = list(c(0, 40), c(41, 100))) |>
    PatientProfiles::addSex(name = "table") |>
    summariseCohortOverlap(
      cohortId = 1:2,
      strata = list("age_group", c("age_group", "sex"))
    )

  expect_identical(overlap3, overlap4)

  mockDisconnect(cdm)
})

test_that("expect result is deterministic", {
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

  cdm1 <- CDMConnector::copyCdmTo(
    con = duckdb::dbConnect(duckdb::duckdb()), cdm = cdm, schema = "main"
  )
  cdm1$cohort <- cdm1$cohort |>
    PatientProfiles::addDemographics(
      age = FALSE, priorObservation = FALSE, futureObservation = FALSE,
      ageGroup = aG, name = "cohort"
    ) |>
    omopgenerics::newCohortTable()

  cdm2 <- CDMConnector::copyCdmTo(
    con = duckdb::dbConnect(duckdb::duckdb()), cdm = cdm, schema = "main"
  )
  cdm2$cohort <- cdm2$cohort |>
    PatientProfiles::addDemographics(
      age = FALSE, priorObservation = FALSE, futureObservation = FALSE,
      ageGroup = aG, name = "cohort"
    ) |>
    omopgenerics::newCohortTable()

  result1 <- cdm1$cohort |>
    summariseCohortOverlap(strata = st)

  result2 <- cdm2$cohort |>
    summariseCohortOverlap(strata = st)

  expect_identical(result1, result2)

  CDMConnector::cdmDisconnect(cdm1)
  CDMConnector::cdmDisconnect(cdm2)
})

test_that("test countBy", {
  person <- dplyr::tibble(
    person_id = 1:4L,
    gender_concept_id = 8532L,
    year_of_birth = 1950L,
    month_of_birth = 1L,
    day_of_birth = 1L,
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )
  cohort <- dplyr::tibble(
    cohort_definition_id = c(1L, 1L, 1L, 1L, 2L, 2L, 2L, 2L, 2L),
    subject_id = c(1L, 2L, 3L, 4L, 1L, 1L, 1L, 2L, 4L),
    cohort_start_date = as.Date("2020-01-01"),
    cohort_end_date = as.Date("2020-12-31"),
    variable1 = c("A", "A", "A", "A", "A", "A", "B", "B", "A"),
    variable2 = c("x", "y", "y", "y", "x", "y", "z", "z", "y")
  )
  obs <- dplyr::tibble(
    observation_period_id = 1:4L,
    person_id = 1:4L,
    observation_period_start_date = as.Date("1930-01-01"),
    observation_period_end_date = as.Date("2025-01-01"),
    period_type_concept_id = 0L
  )

  cdm <- mockCohortCharacteristics(
    con = connection(), writeSchema = writeSchema(),
    person = person, observation_period = obs, cohort = cohort
  )

  filterOverlap <- function(x) {
    x |>
      dplyr::filter(.data$estimate_name == "count") |>
      getUniqueCombinationsSr() |>
      dplyr::arrange(.data$variable_name) |>
      dplyr::pull("estimate_value") |>
      as.numeric()
  }

  # order: overlap, (1&2), comparator (2), reference (1)

  # only subject_id
  summariseCohortOverlap(cdm$cohort) |>
    filterOverlap() |>
    expect_identical(c(3, 0, 1))

  # subject_id and variable1
  cdm$cohort |>
    summariseCohortOverlap(overlapBy = c("subject_id", "variable1")) |>
    filterOverlap() |>
    expect_identical(c(2, 2, 2))

  # subject_id and variable2
  cdm$cohort |>
    summariseCohortOverlap(overlapBy = c("subject_id", "variable2")) |>
    filterOverlap() |>
    expect_identical(c(2, 3, 2))

  # subject_id, variable1 and variable2
  cdm$cohort |>
    summariseCohortOverlap(overlapBy = c("subject_id", "variable1", "variable2")) |>
    filterOverlap() |>
    expect_identical(c(2, 3, 2))

  # variable1
  cdm$cohort |>
    summariseCohortOverlap(overlapBy = "variable1") |>
    filterOverlap() |>
    expect_identical(c(1, 1, 0))

  mockDisconnect(cdm)
})
