test_that("basic functionality summarise large scale characteristics", {
  skip_on_cran()
  person <- dplyr::tibble(
    person_id = c(1L, 2L),
    gender_concept_id = c(8507L, 8532L),
    year_of_birth = c(1990L, 1992L),
    month_of_birth = c(1L, 1L),
    day_of_birth = c(1L, 1L),
    race_concept_id = 0L,
    ethnicity_concept_id = 0L
  )
  observation_period <- dplyr::tibble(
    observation_period_id = c(1L, 2L),
    person_id = c(1L, 2L),
    observation_period_start_date = as.Date(c("2011-10-07", "2000-01-01")),
    observation_period_end_date = as.Date(c("2031-10-07", "2030-01-01")),
    period_type_concept_id = 44814724L
  )
  cohort_interest <- dplyr::tibble(
    cohort_definition_id = c(1L, 1L, 1L, 2L),
    subject_id = c(1L, 1L, 2L, 2L),
    cohort_start_date = as.Date(c(
      "2012-10-10", "2015-01-01", "2013-10-10", "2015-01-01"
    )),
    cohort_end_date = as.Date(c(
      "2012-10-10", "2015-01-01", "2013-10-10", "2015-01-01"
    ))
  )
  drug_exposure <- dplyr::tibble(
    drug_exposure_id = 1:11L,
    person_id = c(rep(1L, 8), rep(2L, 3)),
    drug_concept_id = c(
      rep(1125315L, 2), rep(1503328L, 5), 1516978L, 1125315L, 1503328L, 1516978L
    ),
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
    person_id = c(rep(1L, 4), rep(2L, 4)),
    condition_concept_id = c(
      317009L, 378253L, 378253L, 4266367L, 317009L, 317009L, 378253L, 4266367L
    ),
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
  con <- connection()
  cdm <- mockCohortCharacteristics(
    con = con, writeSchema = writeSchema(),
    person = person, observation_period = observation_period,
    cohort_interest = cohort_interest, drug_exposure = drug_exposure,
    condition_occurrence = condition_occurrence
  )
  concept <- dplyr::tibble(
    concept_id = c(1125315L, 1503328L, 1516978L, 317009L, 378253L, 4266367L),
    domain_id = NA_character_,
    vocabulary_id = NA_character_,
    concept_class_id = NA_character_,
    concept_code = NA_character_,
    valid_start_date = as.Date("1900-01-01"),
    valid_end_date = as.Date("2099-01-01")
  ) |>
    dplyr::mutate(concept_name = paste0("concept: ", .data$concept_id))
  name <- CDMConnector::inSchema(schema = writeSchema(), table = "concept")
  DBI::dbWriteTable(conn = con, name = name, value = concept, overwrite = TRUE)
  cdm$concept <- dplyr::tbl(con, name)

  expect_no_error(
    result <- cdm$cohort_interest |>
      summariseLargeScaleCharacteristics(
        eventInWindow = c("condition_occurrence", "drug_exposure"),
        minimumFrequency = 0
      )
  )
  result <- result |> omopgenerics::splitAdditional()
  conceptId <- c(317009, 317009, 378253, 378253, 4266367, 4266367)
  windowName <- rep(c("0 to 0", "-inf to -366"), 3)
  cohortName <- rep(c("cohort_1"), 6)
  count <- c(NA, 2, NA, 1, NA, 2)
  den <- c(3, 3, 3, 3, 3, 3)
  percentage <- as.character(round((100 * count / den), 2))
  for (k in seq_along(conceptId)) {
    r <- result |>
      dplyr::filter(
        .data$concept_id == .env$conceptId[k] &
          .data$variable_level == .env$windowName[k] &
          .data$group_level == .env$cohortName[k]
      )
    if (is.na(count[k])) {
      expect_true(nrow(r) == 0)
    } else {
      expect_true(nrow(r) == 2)
      expect_true(r$estimate_value[r$estimate_name == "count"] == count[k])
      expect_true(r$estimate_value[r$estimate_name == "percentage"] == percentage[k])
    }
  }

  expect_no_error(
    result <- cdm$cohort_interest |>
      summariseLargeScaleCharacteristics(
        episodeInWindow = c("condition_occurrence", "drug_exposure"),
        minimumFrequency = 0
      )
  )
  result <- result |> omopgenerics::splitAdditional()
  conceptId <- c(317009, 317009, 378253, 378253, 4266367, 4266367)
  windowName <- rep(c("0 to 0", "-inf to -366"), 3)
  cohortName <- rep(c("cohort_1"), 6)
  count <- c(1, 2, 1, 1, 2, 2)
  den <- c(3, 3, 3, 3, 3, 3)
  percentage <- as.character(round(100 * count / den, 2))
  for (k in seq_along(conceptId)) {
    r <- result |>
      dplyr::filter(
        .data$concept_id == .env$conceptId[k] &
          .data$variable_level == .env$windowName[k] &
          .data$group_level == .env$cohortName[k]
      )
    if (is.na(count[k])) {
      expect_true(nrow(r) == 0)
    } else {
      expect_true(nrow(r) == 2)
      expect_true(r$estimate_value[r$estimate_name == "count"] == count[k])
      expect_true(r$estimate_value[r$estimate_name == "percentage"] == percentage[k])
    }
  }

  expect_no_error(
    result <- cdm$cohort_interest |>
      PatientProfiles::addDemographics(
        ageGroup = list(c(0, 24), c(25, 150))
      ) |>
      summariseLargeScaleCharacteristics(
        strata = list("age_group", c("age_group", "sex")),
        episodeInWindow = c("condition_occurrence", "drug_exposure"),
        minimumFrequency = 0
      )
  )
  expect_true(all(c("cohort_1", "cohort_2") %in% result$group_level))
  expect_true(all(c("overall", "age_group", "age_group &&& sex") %in% result$strata_name))
  expect_true(all(c(
    "overall", "0 to 24", "25 to 150", "0 to 24 &&& Female",
    "25 to 150 &&& Male", "0 to 24 &&& Male"
  ) %in% result$strata_level))
  result <- result |>
    dplyr::filter(strata_level == "0 to 24 &&& Female")
  result <- result |> omopgenerics::splitAdditional()
  conceptId <- c(317009, 317009, 378253, 378253, 4266367, 4266367)
  windowName <- rep(c("0 to 0", "-inf to -366"), 3)
  cohortName <- rep(c("cohort_1"), 6)
  count <- c(NA, 1, 1, NA, NA, NA)
  den <- c(1, 1, 1, 1, 1, 1)
  percentage <- sprintf("%.2f", 100 * count / den)
  for (k in seq_along(conceptId)) {
    r <- result |>
      dplyr::filter(
        .data$concept_id == .env$conceptId[k] &
          .data$variable_level == .env$windowName[k] &
          .data$group_level == .env$cohortName[k]
      )
    if (is.na(count[k])) {
      expect_true(nrow(r) == 0)
    } else {
      expect_true(nrow(r) == 2)
      expect_true(r$estimate_value[r$estimate_name == "count"] == count[k])
      expect_true(r$estimate_value[r$estimate_name == "percentage"] == percentage[k])
    }
  }

  expect_true(inherits(result, "summarised_result"))

  expect_no_error(
    result <- cdm$cohort_interest |>
      summariseLargeScaleCharacteristics(
        episodeInWindow = c("condition_occurrence", "drug_exposure"),
        minimumFrequency = 0, excludedCodes = 317009
      )
  )
  expect_false(any(grepl("317009", result$additional_level)))

  # check strata
  # all missing values
  cdm$cohort1 <- cdm$cohort1 |>
    dplyr::mutate(my_strata = NA)
  expect_warning(cdm$cohort1 |>
    summariseLargeScaleCharacteristics(
      eventInWindow = c("condition_occurrence", "drug_exposure"),
      strata = list("my_strata"),
      minimumFrequency = 0
    ))
  # some missing
  expect_warning(cdm$cohort1 |>
    dplyr::mutate(my_strata_2 = dplyr::if_else(row_number() == 1,
      "1", NA
    )) |>
    summariseLargeScaleCharacteristics(
      eventInWindow = c("condition_occurrence", "drug_exposure"),
      strata = list("my_strata_2"),
      minimumFrequency = 0
    ))
  # multiple variables
  expect_warning(expect_warning(cdm$cohort1 |>
    dplyr::mutate(
      my_strata_1 = NA,
      my_strata_2 = dplyr::if_else(row_number() == 1,
        "1", NA
      ),
      my_strata_3 = 1L
    ) |>
    summariseLargeScaleCharacteristics(
      eventInWindow = c("condition_occurrence", "drug_exposure"),
      strata = list(
        "my_strata_1",
        "my_strata_2",
        "my_strata_3"
      ),
      minimumFrequency = 0
    )))

  # minimum frequencey
  expect_message(result <- cdm$cohort_interest |>
    summariseLargeScaleCharacteristics(
      eventInWindow = c("condition_occurrence", "drug_exposure"),
      minimumFrequency = 0.5
    ))

  # empty event table
  cdm$visit_occurrence <- cdm$visit_occurrence |>
    dplyr::filter(visit_occurrence_id == 9999)
  expect_no_error(cdm$cohort_interest |>
    summariseLargeScaleCharacteristics(
      episodeInWindow = c("visit_occurrence"),
      minimumFrequency = 0
    ))
  # empty cohort, empty event table
  cdm$cohort2 <- cdm$cohort2 |>
    dplyr::filter(cohort_definition_id == 9999)
  expect_no_error(cdm$cohort2 |>
    summariseLargeScaleCharacteristics(
      episodeInWindow = c("visit_occurrence"),
      minimumFrequency = 0
    ))
  # empty cohort, empty event table, strata all missing
  expect_no_error(cdm$cohort2 |>
    dplyr::mutate(my_strata_1 = NA) |>
    summariseLargeScaleCharacteristics(
      episodeInWindow = c("visit_occurrence"),
      minimumFrequency = 0
    ))

  # create eunomia reference
  dbName <- "GiBleed"
  CDMConnector::requireEunomia(datasetName = dbName)
  con <- duckdb::dbConnect(drv = duckdb::duckdb(dbdir = CDMConnector::eunomiaDir(datasetName = dbName)))
  cdm <- CDMConnector::cdmFromCon(con = con, cdmSchema = "main", writeSchema = "main")

  cdm <- CDMConnector::generateConceptCohortSet(cdm = cdm,
                                                conceptSet = list(avp = 4112343),
                                                name = "my_cohort")

  # include source table
  expect_no_error(
    result1 <- cdm$my_cohort |>
      summariseLargeScaleCharacteristics(
        window = list(c(-Inf, -1), c(1, Inf)),
        eventInWindow = "condition_occurrence",
        includeSource = FALSE
      )
  )
  expect_true("concept_id" %in% colnames(tidy(result1)))
  expect_no_error(
    result2 <- cdm$my_cohort |>
      summariseLargeScaleCharacteristics(
        window = list(c(-Inf, -1), c(1, Inf)),
        eventInWindow = "condition_occurrence",
        includeSource = TRUE
      )
  )
  result2 <- tidy(result2)
  expect_true(all(c("concept_id", "source_concept_id", "source_concept_name") %in% colnames(result2)))
  expect_true(
    result2 |>
      dplyr::filter(.data$concept_id != .data$source_concept_id) |>
      dplyr::filter(.data$variable_name != .data$source_concept_name) |>
      nrow() > 0
  )
  expect_identical(
    result2$source_concept_name[result2$source_concept_id == "4166590"],
    "UNKNOWN CONCEPT"
  )

  # atc 3rd
  expect_no_error(
    result1 <- cdm$my_cohort |>
      PatientProfiles::addSex() |>
      summariseLargeScaleCharacteristics(
        strata = list("sex"), window = list(c(-Inf, -1), c(1, Inf)),
        eventInWindow = "condition_occurrence",
        episodeInWindow = c("ATC 3rd", "drug_exposure"),
        includeSource = FALSE
      )
  )
  result1 <- tidy(result1)
  expect_true("concept_id" %in% colnames(result1))
  expect_false("source_concept_id" %in% colnames(result1))
  expect_false("source_concept_name" %in% colnames(result1))

  expect_no_error(
    result2 <- cdm$my_cohort |>
      PatientProfiles::addSex() |>
      summariseLargeScaleCharacteristics(
        strata = list("sex"), window = list(c(-Inf, -1), c(1, Inf)),
        eventInWindow = "condition_occurrence",
        episodeInWindow = c("ATC 3rd", "drug_exposure"),
        includeSource = TRUE
      )
  )
  result2 <- tidy(result2)
  expect_true("concept_id" %in% colnames(result2))
  expect_true("source_concept_id" %in% colnames(result2))
  expect_true("source_concept_name" %in% colnames(result2))

  # explore atc
  dbName <- "synthea-covid19-10k"
  CDMConnector::requireEunomia(datasetName = dbName)
  cdm <- dbName |>
    CDMConnector::eunomiaDir() |>
    duckdb::duckdb() |>
    duckdb::dbConnect() |>
    CDMConnector::cdmFromCon(cdmSchema = "main", writeSchema = "main") |>
    CDMConnector::generateConceptCohortSet(conceptSet = list(cva = 381316),
                                           name = "my_cohort")
  # atc 3rd
  expect_no_error(
    result1 <- cdm$my_cohort |>
      PatientProfiles::addSex() |>
      summariseLargeScaleCharacteristics(
        strata = list("sex"), window = list(c(-Inf, -1), c(1, Inf)),
        eventInWindow = "condition_occurrence",
        episodeInWindow = c("ATC 3rd", "drug_exposure"),
        includeSource = FALSE
      )
  )
  result1 <- tidy(result1)
  expect_true("concept_id" %in% colnames(result1))
  expect_false("source_concept_id" %in% colnames(result1))
  expect_false("source_concept_name" %in% colnames(result1))
  expect_true(all(c("standard", "ATC 3rd") %in% unique(result1$analysis)))

  expect_no_error(
    result2 <- cdm$my_cohort |>
      PatientProfiles::addSex() |>
      summariseLargeScaleCharacteristics(
        strata = list("sex"), window = list(c(-Inf, -1), c(1, Inf)),
        eventInWindow = "condition_occurrence",
        episodeInWindow = c("ATC 3rd", "drug_exposure"),
        includeSource = TRUE
      )
  )
  result2 <- tidy(result2)
  expect_true("concept_id" %in% colnames(result2))
  expect_true("source_concept_id" %in% colnames(result2))
  expect_true("source_concept_name" %in% colnames(result2))
  expect_true(all(c("standard-source", "ATC 3rd") %in% unique(result2$analysis)))
  expect_true(unique(result2$source_concept_id[result2$analysis == "ATC 3rd"]) == "overall")
  expect_true(unique(result2$source_concept_name[result2$analysis == "ATC 3rd"]) == "overall")

  atc_result1 <- result1 |>
    dplyr::filter(.data$analysis == "ATC 3rd") |>
    dplyr::arrange(dplyr::across(dplyr::everything()))
  atc_result2 <- result2 |>
    dplyr::filter(.data$analysis == "ATC 3rd") |>
    dplyr::arrange(dplyr::across(dplyr::everything())) |>
    dplyr::select(!c("source_concept_id", "source_concept_name"))
  expect_identical(atc_result1, atc_result2)

})
