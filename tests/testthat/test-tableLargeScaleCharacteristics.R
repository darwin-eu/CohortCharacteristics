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
    observation_period_start_date = as.Date(c("2010-10-01", "2010-10-01")),
    observation_period_end_date = as.Date(c("2011-10-01", "2011-10-01")),
    period_type_concept_id = 44814724L
  )
  cohort_interest <- dplyr::tibble(
    cohort_definition_id = c(1L, 1L),
    subject_id = c(1L, 2L),
    cohort_start_date = as.Date(c("2010-10-10", "2010-10-10")),
    cohort_end_date = as.Date(c("2010-12-01", "2010-12-01"))
  )
  # everyone has 1125315 in drug exposure
  drug_exposure <- dplyr::tibble(
    drug_exposure_id = as.integer(1:2),
    person_id = as.integer(1:2),
    drug_concept_id = as.integer(c(rep(1125315, 2))),
    drug_exposure_start_date = as.Date(c("2010-10-01")),
    drug_exposure_end_date = as.Date(c("2010-12-01")),
    drug_type_concept_id = 38000177,
    quantity = 1
  )
  # only one person has 1125315 in condition occurrence
  condition_occurrence <- dplyr::tibble(
    condition_occurrence_id = as.integer(1:2),
    person_id = as.integer(c(rep(1, 2))),
    condition_concept_id = as.integer(c(1125315, 378253)),
    condition_start_date = as.Date(c("2010-10-01", "2010-10-01")),
    condition_end_date = as.Date(c("2010-10-01", "2010-10-01")),
    condition_type_concept_id = 32020L
  )
  con <- connection()
  cdm <- mockCohortCharacteristics(
    con = con,
    writeSchema = writeSchema(),
    person = person,
    observation_period = observation_period,
    cohort_interest = cohort_interest,
    drug_exposure = drug_exposure,
    condition_occurrence = condition_occurrence
  )
  concept <- dplyr::tibble(
    concept_id = as.integer(c(
      1125315, 1503328, 1516978, 317009, 378253, 4266367
    )),
    domain_id = as.integer(NA),
    vocabulary_id = as.integer(NA),
    concept_class_id = as.integer(NA),
    concept_code = as.integer(NA),
    valid_start_date = as.Date("1900-01-01"),
    valid_end_date = as.Date("2099-01-01")
  ) |>
    dplyr::mutate(concept_name = paste0("concept: ", .data$concept_id))
  name <- CDMConnector::inSchema(schema = "main", table = "concept")
  DBI::dbWriteTable(
    conn = con,
    name = name,
    value = concept,
    overwrite = TRUE
  )
  cdm$concept <- dplyr::tbl(con, name)

  result <- cdm$cohort_interest |>
    summariseLargeScaleCharacteristics(
      eventInWindow = c("condition_occurrence", "drug_exposure"),
      window = c(-Inf, Inf),
      minimumFrequency = 0
    )

  expect_no_error(tableLargeScaleCharacteristics(result))
})

test_that("topConcepts working", {
  skip_on_cran()
  con <- duckdb::dbConnect(duckdb::duckdb(), dbdir = CDMConnector::eunomiaDir())
  cdm <- CDMConnector::cdmFromCon(
    con = con, cdmSchem = "main", writeSchema = "main", cdmName = "Eunomia"
  )

  cdm <- CDMConnector::generateConceptCohortSet(
    cdm = cdm,
    name = "ankle_sprain",
    conceptSet = list("ankle_sprain" = 81151),
    end = "event_end_date",
    limit = "first",
    overwrite = TRUE
  )

  lsc <- cdm$ankle_sprain |>
    summariseLargeScaleCharacteristics(
      window = list(c(-Inf, -1), c(0, 0)),
      eventInWindow = c("condition_occurrence", "procedure_occurrence"),
      episodeInWindow = "drug_exposure",
      minimumFrequency = 0.1
    )

  x <- tableLargeScaleCharacteristics(lsc, topConcepts = 1, type = "tibble")

  expect_true(nrow(x) == 1)

  CDMConnector::cdmDisconnect(cdm)
})
