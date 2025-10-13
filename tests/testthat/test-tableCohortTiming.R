test_that("tableCohortTiming", {
  skip_on_cran()
  person <- dplyr::tibble(
    person_id = 1:20L,
    gender_concept_id = 8532L,
    year_of_birth = sample(1950:1970L, size = 20, replace = TRUE),
    month_of_birth = sample(1:12L, size = 20, replace = TRUE),
    day_of_birth = sample(1:28L, size = 20, replace = TRUE),
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )

  table <- dplyr::tibble(
    cohort_definition_id = c(rep(1L, 15), rep(2L, 10), rep(3L, 15), rep(4L, 5)),
    subject_id = c(
      20, 5, 10, 12, 4, 15, 2, 1, 5, 10, 5, 8, 13, 4, 10, 6, 18, 5, 1, 20, 14,
      13, 8, 17, 3, 16, 15, 20, 17, 3, 14, 6, 11, 8, 7, 20, 19, 5, 2, 18, 5, 12,
      3, 14, 13
    ) |>
      as.integer(),
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
  tibble1 <- tableCohortTiming(
    timing1,
    type = "tibble",
    header = omopgenerics::strataColumns(timing1)
  )
  expect_true(all(c(
    "CDM name", "Cohort name reference", "Cohort name comparator",
    "Variable name", "Estimate name", "Estimate value"
  ) %in%
    colnames(tibble1)))
  expect_true(nrow(tibble1 |> dplyr::distinct(`Cohort name reference`, `Cohort name comparator`)) == 6)
  expect_true(all(unique(tibble1$`Estimate name`) %in% c("N", "Median [Q25 - Q75]", "Range")))

  tibble2 <- tableCohortTiming(timing1, type = "tibble", header = "cohort_name")

  tibble3 <- tableCohortTiming(timing1, type = "tibble", uniqueCombinations = FALSE)
  expect_true(all(unique(tibble3$`Cohort name comparator`) %in%
    unique(tibble3$`Cohort name reference`)))

  tibble4 <- tableCohortTiming(timing1, type = "tibble", header = "cohort_name")
  gt1 <- tableCohortTiming(timing1, type = "gt")
  expect_true("gt_tbl" %in% class(gt1))

  fx1 <- tableCohortTiming(timing1, type = "flextable")
  expect_true("flextable" %in% class(fx1))

  # years
  tibbleDays <- tableCohortTiming(
    timing1,
    timeScale = "days", type = "tibble", header = "cohort_name"
  )
  tibbleYears <- tableCohortTiming(
    timing1,
    timeScale = "years", type = "tibble", header = "cohort_name"
  )

  # strata ----
  cdm$table <- cdm$table |>
    PatientProfiles::addAge(ageGroup = list(c(0, 40), c(41, 150))) |>
    PatientProfiles::addSex() |>
    dplyr::compute(name = "table", temporary = FALSE) |>
    omopgenerics::newCohortTable()
  timing2 <- summariseCohortTiming(cdm$table,
    strata = list("age_group", c("age_group", "sex"))
  )

  fx2 <- tableCohortTiming(timing2,
    type = "flextable"
  )
  expect_true(class(fx2) == "flextable")

  gt2 <- tableCohortTiming(timing2)
  expect_true("gt_tbl" %in% class(gt2))

  gt3 <- tableCohortTiming(
    timing2 |>
      dplyr::filter(grepl("cohort_1", group_level)) |>
      dplyr::filter(grepl("2|3", group_level)),
    header = c("cdm_name", "cohort_name", "age_group", "sex"),
    groupColumn = character()
  )
  expect_true("gt_tbl" %in% class(gt3))

  dropCreatedTables(cdm = cdm)
})
