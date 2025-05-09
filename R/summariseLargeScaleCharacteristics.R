# Copyright 2024 DARWIN EU (C)
#
# This file is part of CohortCharacteristics
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' This function is used to summarise the large scale characteristics of a
#' cohort table
#'
#' @inheritParams cohortDoc
#' @inheritParams cohortIdDoc
#' @inheritParams strataDoc
#' @param window Temporal windows that we want to characterize.
#' @param eventInWindow Tables to characterise the events in the window. eventInWindow must be provided if episodeInWindow is not specified.
#' @param episodeInWindow Tables to characterise the episodes in the window. episodeInWindow must be provided if eventInWindow is not specified.
#' @param indexDate Variable in x that contains the date to compute the
#' intersection.
#' @param censorDate whether to censor overlap events at a specific date
#' or a column date of x
#' @param includeSource Whether to include source concepts.
#' @param minimumFrequency Minimum frequency of codes to be reported. If a
#' concept_id has a frequency smaller than `minimumFrequency` in a certain
#' window that estimate will be eliminated from the result object.
#' @param excludedCodes Codes excluded.
#'
#' @return The output of this function is a `ResultSummary` containing the
#' relevant information.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(CohortCharacteristics)
#' library(duckdb)
#' library(CDMConnector)
#' library(DrugUtilisation)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' con <- dbConnect(duckdb(), eunomiaDir())
#' cdm <- cdmFromCon(con, cdmSchem = "main", writeSchema = "main")
#'
#' cdm <- generateIngredientCohortSet(
#'   cdm = cdm, name = "my_cohort", ingredient = "acetaminophen"
#' )
#'
#' cdm$my_cohort |>
#'   summariseLargeScaleCharacteristics(
#'     window = list(c(-365, -1), c(1, 365)),
#'     eventInWindow = "condition_occurrence"
#'   ) |>
#'   glimpse()
#'
#' cdmDisconnect(cdm)
#' }
summariseLargeScaleCharacteristics <- function(cohort,
                                               cohortId = NULL,
                                               strata = list(),
                                               window = list(
                                                 c(-Inf, -366), c(-365, -31),
                                                 c(-30, -1), c(0, 0), c(1, 30),
                                                 c(31, 365), c(366, Inf)
                                               ),
                                               eventInWindow = NULL,
                                               episodeInWindow = NULL,
                                               indexDate = "cohort_start_date",
                                               censorDate = NULL,
                                               includeSource = FALSE,
                                               minimumFrequency = 0.005,
                                               excludedCodes = c(0)) {
  cdm <- omopgenerics::cdmReference(cohort)

  # initial checks
  cohortId <- omopgenerics::validateCohortIdArgument({cohortId}, cohort = cohort)
  checkX(cohort)
  checkStrata(strata, cohort)
  window <- omopgenerics::validateWindowArgument(window, snakeCase = FALSE)
  tables <- c(
    "visit_occurrence", "condition_occurrence", "drug_exposure",
    "procedure_occurrence", "device_exposure", "measurement", "observation",
    "drug_era", "condition_era", "specimen",
    paste("ATC", c("1st", "2nd", "3rd", "4th", "5th"))
  )
  omopgenerics::assertChoice(eventInWindow, tables, null = TRUE)
  omopgenerics::assertChoice(episodeInWindow, tables, null = TRUE)
  if (is.null(eventInWindow) && is.null(episodeInWindow)) {
    cli::cli_abort("'eventInWindow' or 'episodeInWindow' must be provided")
  }
  omopgenerics::assertLogical(includeSource, length = 1)
  omopgenerics::assertNumeric(minimumFrequency, min = 0, max = 1)
  omopgenerics::assertNumeric(excludedCodes, integerish = TRUE, null = TRUE)

  cdm <- omopgenerics::validateCdmArgument(cdm)

  # warn if strata has missing values
  for (k in seq_along(strata)) {
    missingWorkingStrata <- cohort |>
      dplyr::filter(is.na(!!as.symbol(strata[[k]]))) |>
      dplyr::tally() |>
      dplyr::pull("n")
    if (missingWorkingStrata > 0) {
      cli::cli_warn("{missingWorkingStrata} missing value{?s} in
                    variable {strata[[k]]} will be dropped when
                    calculating stratified results")
    }
  }

  # random tablePrefix
  tablePrefix <- omopgenerics::tmpPrefix()

  # initial table
  cohort <- PatientProfiles::filterCohortId(cohort = cohort, cohortId = cohortId)
  x <- getInitialTable(cohort, tablePrefix, indexDate, censorDate)

  # get analysis table
  analyses <- getAnalyses(eventInWindow, episodeInWindow, includeSource)

  minWindow <- min(unlist(window))
  maxWindow <- max(unlist(window))

  # perform lsc
  lsc <- NULL
  cli::cli_alert_info("Summarising large scale characteristics ")
  tables <- unique(analyses$table)
  for (i in seq_along(tables)) {
    tab <- unique(analyses$table)[i]
    " - getting characteristics from table {.pkg {tab}} ({i} of {length(tables)})" |>
      cli::cli_progress_message()
    analysesTable <- analyses |> dplyr::filter(.data$table == .env$tab)
    table <- getTable(
      tab, x, includeSource, minWindow, maxWindow, tablePrefix
    )
    for (k in seq_len(nrow(analysesTable))) {
      tableAnalysis <- getTableAnalysis(table, analysesTable[k, ], tablePrefix)
      for (win in seq_along(window)) {
        tableWindow <- getTableWindow(tableAnalysis, window[[win]], tablePrefix)
        lsc <- lsc |>
          dplyr::bind_rows(
            summariseConcept(cohort, tableWindow, strata, tablePrefix) |>
              dplyr::mutate(
                "window_name" = names(window)[win],
                "table_name" = .env$tab,
                "analysis" = .env$analysesTable$analysis[k],
                "type" = .env$analysesTable$type[k]
              )
          )
      }
    }
  }

  cli::cli_progress_message("Formatting result")
  # calculate denominators
  den <- denominatorCounts(cohort, x, strata, window, tablePrefix)

  if (includeSource) {
    addCols <- c("concept_id", "source_concept_id", "source_concept_name")
  } else {
    addCols <- "concept_id"
  }

  # format results
  results <- lsc |>
    addPercentages(den) |>
    trimFrequency(minimumFrequency) |>
    excludeLscCodes(excludedCodes) |>
    PatientProfiles::addCdmName(cdm = cdm) |>
    addConceptNames(cdm) |>
    dplyr::rename(variable_level = "window_name") |>
    dplyr::mutate(count = sprintf("%i", .data$count)) |>
    tidyr::pivot_longer(
      cols = c("count", "percentage"),
      names_to = "estimate_name",
      values_to = "estimate_value"
    ) |>
    dplyr::mutate(estimate_type = dplyr::if_else(
      .data$estimate_name == "count", "integer", "percentage"
    )) |>
    omopgenerics::uniteAdditional(cols = addCols)

  # add result_id
  sets <- results |>
    dplyr::select("table_name", "type", "analysis") |>
    dplyr::distinct() |>
    dplyr::mutate(result_id = as.integer(dplyr::row_number()))
  results <- results |>
    dplyr::left_join(sets, by = c("table_name", "type", "analysis")) |>
    dplyr::select(-"table_name", -"type", -"analysis") |>
    omopgenerics::newSummarisedResult(
      settings = sets |>
        dplyr::mutate(
          result_type = "summarise_large_scale_characteristics",
          package_name = "CohortCharacteristics",
          package_version = pkgVersion()
        )
    )

  # order final result
  group <- dplyr::tibble(
    group_level = omopgenerics::settings(cohort)$cohort_name
  )
  strata <- getStratas(cohort, strata)
  variableLevel <- dplyr::tibble(variable_level = sortWindow(window))
  combs <- getCombinations(group, strata, variableLevel) |>
    dplyr::mutate(order_id = dplyr::row_number())
  results <- results |>
    dplyr::left_join(
      combs,
      by = c("group_level", "strata_name", "strata_level", "variable_level"),
      relationship = "many-to-many"
    ) |>
    dplyr::arrange(
      .data$result_id, .data$order_id, .data$variable_name, .data$estimate_name
    ) |>
    dplyr::select(!"order_id")

  # eliminate permanent tables
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(tablePrefix))

  cli::cli_inform(c(v = "Summarising large scale characteristics "))

  # return
  return(results)
}

getAnalyses <- function(eventInWindow, episodeInWindow, includeSource) {
  atc <- c("ATC 1st", "ATC 2nd", "ATC 3rd", "ATC 4th", "ATC 5th")
  icd10 <- c("icd10 chapter", "icd10 subchapter")
  analysis <- ifelse(includeSource, "standard-source", "standard")
  dplyr::tibble(table = eventInWindow %||% character(), type = "event") |>
    dplyr::union_all(
      dplyr::tibble(table = episodeInWindow %||% character(), type = "episode")
    ) |>
    dplyr::mutate(
      analysis = dplyr::if_else(
        .data$table %in% c(.env$atc, .env$icd10), .data$table, .env$analysis
      ),
      table = dplyr::case_when(
        .data$table %in% .env$icd10 ~ "condition_occurrence",
        .data$table %in% .env$atc ~ "drug_exposure",
        .default = .data$table
      )
    )
}
getInitialTable <- function(cohort, tablePrefix, indexDate, censorDate) {
  x <- cohort |>
    PatientProfiles::addDemographics(
      indexDate = indexDate, age = FALSE, sex = FALSE,
      priorObservationName = "start_obs", futureObservationName = "end_obs"
    ) |>
    dplyr::mutate(start_obs = -.data$start_obs)
  if (!is.null(censorDate)) {
    x <- x %>% # to be removed
      dplyr::mutate("censor_obs" = !!CDMConnector::datediff(indexDate, censorDate)) |>
      dplyr::mutate("end_obs" = dplyr::if_else(
        is.na(.data$censor_obs) | .data$censor_obs > .data$end_obs,
        .data$end_obs,
        .data$censor_obs
      ))
  }
  x <- x |>
    dplyr::select(
      "subject_id",
      "cohort_start_date" = dplyr::all_of(indexDate), "start_obs",
      "end_obs"
    ) |>
    dplyr::distinct() |>
    dbplyr::window_order(.data$subject_id, .data$cohort_start_date) |>
    dplyr::mutate(obs_id = dplyr::row_number()) |>
    dbplyr::window_order() |>
    dplyr::compute(name = paste0(tablePrefix, "individuals"))
  return(x)
}
getTable <- function(tab, x, includeSource, minWindow, maxWindow, tablePrefix) {
  cdm <- omopgenerics::cdmReference(x)
  toSelect <- c(
    "subject_id" = "person_id",
    "start_diff" = PatientProfiles::startDateColumn(tab),
    "end_diff" = PatientProfiles::endDateColumn(tab) |>
      dplyr::coalesce(PatientProfiles::startDateColumn(tab)),
    "standard" = PatientProfiles::standardConceptIdColumn(tab),
    "source" = PatientProfiles::sourceConceptIdColumn(tab)
  )
  if (includeSource == FALSE || is.na(PatientProfiles::sourceConceptIdColumn(tab))) {
    toSelect <- toSelect["source" != names(toSelect)]
  }
  table <- cdm[[tab]] |>
    dplyr::select(dplyr::all_of(toSelect)) |>
    dplyr::inner_join(x, by = "subject_id") |>
    dplyr::mutate(end_diff = dplyr::coalesce(.data$end_diff, .data$start_diff)
    ) %>% # to be removed
    dplyr::mutate(start_diff = !!CDMConnector::datediff(
      "cohort_start_date", "start_diff"
    )) %>% # to be removed
    dplyr::mutate(end_diff = !!CDMConnector::datediff(
      "cohort_start_date", "end_diff"
    )) |>
    dplyr::filter(
      .data$end_diff >= .data$start_obs & .data$start_diff <= .data$end_obs
    )
  if (!is.infinite(minWindow)) {
    table <- table |>
      dplyr::filter(.data$end_diff >= .env$minWindow)
  }
  if (!is.infinite(maxWindow)) {
    table <- table |>
      dplyr::filter(.data$start_diff <= .env$maxWindow)
  }
  table <- table |>
    dplyr::select(-"start_obs", -"end_obs") |>
    dplyr::compute(name = paste0(tablePrefix, "table"))

  return(table)
}
summariseConcept <- function(cohort, tableWindow, strata, tablePrefix) {
  result <- NULL
  cohortNames <- omopgenerics::settings(cohort)$cohort_name
  for (cohortName in cohortNames) {
    cdi <- omopgenerics::settings(cohort) |>
      dplyr::filter(.data$cohort_name == .env$cohortName) |>
      dplyr::pull("cohort_definition_id")
    tableWindowCohort <- tableWindow |>
      dplyr::inner_join(
        cohort |>
          dplyr::filter(.data$cohort_definition_id == .env$cdi),
        by = c("subject_id", "cohort_start_date")
      ) |>
      dplyr::select(
        "obs_id", dplyr::any_of(c("concept", "source")),
        dplyr::all_of(unique(unlist(strata)))
      ) |>
      dplyr::compute(
        name = paste0(tablePrefix, "table_window_cohort"),
        temporary = FALSE,
        overwrite = TRUE
      )
    result <- result |>
      dplyr::bind_rows(
        tableWindowCohort |>
          dplyr::group_by(dplyr::across(dplyr::any_of(c("concept", "source")))) |>
          dplyr::summarise(count = as.numeric(dplyr::n()), .groups = "drop") |>
          dplyr::collect() |>
          dplyr::mutate(strata_name = "overall", strata_level = "overall") |>
          dplyr::bind_rows(summariseStrataCounts(tableWindowCohort, strata)) |>
          dplyr::mutate(group_name = "cohort_name", group_level = cohortName)
      )
  }
  return(result)
}
summariseStrataCounts <- function(tableWindowCohort, strata) {
  result <- NULL
  for (k in seq_along(strata)) {
    result <- result |>
      dplyr::union_all(
        tableWindowCohort |>
          dplyr::group_by(dplyr::across(dplyr::any_of(c(
            "concept", "source", strata[[k]]
          )))) |>
          dplyr::summarise(count = as.numeric(dplyr::n()), .groups = "drop") |>
          dplyr::collect() |>
          dplyr::filter(!is.na(!!as.symbol(strata[[k]]))) |>
          omopgenerics::uniteStrata(cols = strata[[k]])
      )
  }
  return(result)
}
denominatorCounts <- function(cohort, x, strata, window, tablePrefix) {
  table <- x |>
    dplyr::rename("start_diff" = "start_obs", "end_diff" = "end_obs") |>
    dplyr::mutate(concept = "denominator")
  den <- NULL
  for (win in seq_along(window)) {
    tableWindow <- getTableWindow(table, window[[win]], tablePrefix)
    den <- den |>
      dplyr::bind_rows(
        summariseConcept(cohort, tableWindow, strata, tablePrefix) |>
          dplyr::mutate(window_name = names(window)[win])
      )
  }
  return(den)
}
addPercentages <- function(lsc, den) {
  lsc |>
    dplyr::inner_join(
      den |>
        dplyr::rename("denominator" = "count") |>
        dplyr::select(!"concept"),
      by = c(
        "strata_name", "strata_level", "group_name", "group_level",
        "window_name"
      )
    ) |>
    dplyr::mutate(percentage = sprintf("%.2f", 100 * .data$count / .data$denominator)) |>
    dplyr::select(!"denominator")
}
trimFrequency <- function(lsc, minimumFrequency) {
  start_rows <- nrow(lsc)
  lsc <- lsc |>
    dplyr::filter(.data$percentage >= 100 * .env$minimumFrequency)
  end_rows <- nrow(lsc)

  if (end_rows < start_rows) {
    "{start_rows - end_rows} estimate{?s} dropped as frequency less than {paste0(minimumFrequency*100)}%" |>
      cli::cli_inform()
  }
  return(lsc)
}
excludeLscCodes <- function(lsc, excludedCodes) {
  n_start <- nrow(lsc)
  if ("source" %in% colnames(lsc)) {
    lsc <- lsc |>
      dplyr::filter(
        !.data$concept %in% .env$excludedCodes |
          !.data$source %in% .env$excludedCodes
      )
  } else if ("concept" %in% colnames(lsc)) {
    lsc <- lsc |>
      dplyr::filter(!.data$concept %in% .env$excludedCodes)
  }
  n_end <- nrow(lsc)

  if (n_end < n_start) {
    "{n_start - n_end} estimate{?s} dropped as contain `excludedCodes`." |>
      cli::cli_inform()
  }

  return(lsc)
}
addConceptNames <- function(lsc, cdm) {
  concepts <- suppressWarnings(unique(c(lsc$concept, lsc$source)))
  concepts <- dplyr::tibble(concept_id = concepts)

  nm <- omopgenerics::uniqueTableName(omopgenerics::tmpPrefix())
  cdm <- omopgenerics::insertTable(cdm = cdm, name = nm, table = concepts)

  conceptNames <- cdm[["concept"]] |>
    dplyr::select("concept_id", "concept_name") |>
    dplyr::inner_join(cdm[[nm]], by = "concept_id") |>
    dplyr::collect()

  omopgenerics::dropSourceTable(cdm = cdm, name = nm)

  lsc <- lsc |>
    dplyr::mutate(variable_name = NA_character_, concept_id = NA_integer_)
  if ("concept" %in% colnames(lsc)) {
    lsc <- lsc |>
      dplyr::left_join(
        conceptNames |>
          dplyr::rename(new_name = "concept_name",
                        concept = "concept_id"),
        by = "concept"
      ) |>
      dplyr::mutate(
        variable_name = dplyr::coalesce(.data$variable_name, .data$new_name),
        concept_id = dplyr::coalesce(.data$concept_id, .data$concept),
        variable_name = dplyr::if_else(
          !is.na(.data$concept_id),
          dplyr::coalesce(.data$variable_name, "UNKNOWN CONCEPT"),
          .data$variable_name
        )
      ) |>
      dplyr::select(!c("concept", "new_name"))
  }
  if ("source" %in% colnames(lsc)) {
    lsc <- lsc |>
      dplyr::rename(source_concept_id = "source") |>
      dplyr::left_join(
        conceptNames |>
          dplyr::rename(
            source_concept_id = "concept_id",
            source_concept_name = "concept_name"
          ),
        by = "source_concept_id"
      ) |>
      dplyr::mutate(
        source_concept_name = dplyr::if_else(
          !is.na(.data$source_concept_id),
          dplyr::coalesce(.data$source_concept_name, "UNKNOWN CONCEPT"),
          .data$source_concept_name
        )
      )
  }

  return(lsc)
}
formatLscResult <- function(lsc, den, cdm, minimumFrequency, excludedCodes) {
  lsc <- lsc |>
    dplyr::filter(!.data$concept %in% .env$excludedCodes) |>
    tidyr::pivot_longer(
      cols = c("count", "percentage"), names_to = "estimate_type",
      values_to = "estimate"
    ) |>
    PatientProfiles::addCdmName(cdm = cdm) |>
    dplyr::mutate(
      estimate = as.character(.data$estimate),
      result_type = "Summarised Large Scale Characteristics"
    ) |>
    dplyr::inner_join(addConceptName(lsc, cdm), by = c("concept", "analysis")) |>
    dplyr::select(
      "result_type", "cdm_name", "group_name", "group_level", "strata_name",
      "strata_level", "table_name", "type", "analysis", "concept",
      "variable" = "concept_name", "variable_level" = "window_name",
      "estimate_type", "estimate"
    )

  lsc
}
addConceptName <- function(lsc, cdm) {
  concepts <- lsc |>
    dplyr::select("concept", "analysis") |>
    dplyr::distinct()

  conceptsTblName <- omopgenerics::uniqueTableName(omopgenerics::tmpPrefix())
  cdm <- omopgenerics::insertTable(
    cdm = cdm,
    name = conceptsTblName,
    table = concepts,
    overwrite = TRUE
  )

  conceptNames <- cdm[["concept"]] |>
    dplyr::select("concept" = "concept_id", "concept_name") |>
    dplyr::inner_join(
      cdm[[conceptsTblName]] |>
        dplyr::mutate(concept = as.numeric(.data$concept)),
      by = "concept"
    ) |>
    dplyr::collect()

  omopgenerics::dropSourceTable(cdm = cdm, name = conceptsTblName)

  return(conceptNames)
}
getTableAnalysis <- function(table, analyses, tablePrefix) {
  if (analyses$type == "event") {
    table <- table |>
      dplyr::mutate("end_diff" = .data$start_diff)
  }
  table <- table |>
    dplyr::rename(concept = "standard")
  if (analyses$analysis != "standard-source") {
    table <- table |>
      dplyr::select(!dplyr::any_of("source"))
    if (analyses$analysis != "standard") {
      table <- getCodesGroup(table, analyses$analysis, tablePrefix)
    }
  }
  return(table)
}
getCodesGroup <- function(table, analysis, tablePrefix) {
  cdm <- omopgenerics::cdmReference(table)
  if (analysis %in% c("ATC 1st", "ATC 2nd", "ATC 3rd", "ATC 4th", "ATC 5h")) {
    codes <- cdm[["concept"]] |>
      dplyr::filter(.data$vocabulary_id == "ATC") |>
      dplyr::filter(.data$concept_class_id == .env$analysis) |>
      dplyr::select("concept_new" = "concept_id") |>
      dplyr::inner_join(
        cdm[["concept_ancestor"]] |>
          dplyr::select(
            "concept_new" = "ancestor_concept_id",
            "concept" = "descendant_concept_id"
          ),
        by = "concept_new"
      )
  } else {
    codes <- cdm[["concept"]] |>
      dplyr::filter(.data$vocabulary_id == "ICD10") |>
      dplyr::filter(.data$concept_class_id == .env$analysis) |>
      dplyr::select("concept_new" = "concept_id")
    # TODO
  }
  table <- table |>
    dplyr::inner_join(codes, by = "concept") |>
    dplyr::select(-"concept") |>
    dplyr::rename("concept" = "concept_new") |>
    dplyr::compute(
      name = paste0(tablePrefix, "table_group"),
      temporary = FALSE,
      overwrite = TRUE
    )
  return(table)
}
getTableWindow <- function(table, window, tablePrefix) {
  startWindow <- window[1]
  endWindow <- window[2]
  if (is.infinite(startWindow)) {
    if (is.infinite(endWindow)) {
      tableWindow <- table
    } else {
      tableWindow <- table |>
        dplyr::filter(.data$start_diff <= .env$endWindow)
    }
  } else {
    if (is.infinite(endWindow)) {
      tableWindow <- table |>
        dplyr::filter(.data$end_diff >= .env$startWindow)
    } else {
      tableWindow <- table |>
        dplyr::filter(
          .data$end_diff >= .env$startWindow &
            .data$start_diff <= .env$endWindow
        )
    }
  }
  tableWindow <- tableWindow |>
    dplyr::select("subject_id", "cohort_start_date", "obs_id", "concept",
                  dplyr::any_of("source")) |>
    dplyr::distinct() |>
    dplyr::compute(
      name = paste0(tablePrefix, "table_window"),
      temporary = FALSE,
      overwrite = TRUE
    )
  return(tableWindow)
}
