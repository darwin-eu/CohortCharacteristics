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
  x <- cohort |>
    dplyr::filter(.data$cohort_definition_id %in% .env$cohortId) |>
    getInitialTable(tablePrefix, indexDate, censorDate)

  # get analysis table
  analyses <- getAnalyses(eventInWindow, episodeInWindow)

  minWindow <- min(unlist(window))
  maxWindow <- max(unlist(window))

  # perform lsc
  lsc <- NULL
  cli::cli_alert_info("Summarising large scale characteristics ")
  id <- cli::cli_status("")
  for (i in seq_along(unique(analyses$table))) {
    tab <- unique(analyses$table)[i]
    cli::cli_status_update(
      id,
      " - getting characteristics from table {tab} ({i} of {length(unique(analyses$table))})"
    )
    analysesTable <- analyses |> dplyr::filter(.data$table == .env$tab)
    table <- getTable(
      tab, x, includeSource, minWindow, maxWindow, tablePrefix, excludedCodes
    )
    for (k in seq_len(nrow(analysesTable))) {
      type <- analysesTable$type[k]
      analysis <- analysesTable$analysis[k]
      tableAnalysis <- getTableAnalysis(table, type, analysis, tablePrefix)
      for (win in seq_along(window)) {
        tableWindow <- getTableWindow(tableAnalysis, window[[win]], tablePrefix)
        lsc <- lsc |>
          dplyr::bind_rows(
            summariseConcept(cohort, tableWindow, strata, tablePrefix) |>
              dplyr::mutate(
                "window_name" = names(window)[win],
                "table_name" = .env$tab,
                "analysis" = .env$analysis,
                "type" = .env$type
              )
          )
      }
      if ("source" %in% colnames(table) && analysis == "standard") {
        tableAnalysis <- getTableAnalysis(table, type, "source", tablePrefix)
        for (win in seq_along(window)) {
          tableWindow <- getTableWindow(tableAnalysis, window[[win]], tablePrefix)
          lsc <- lsc |>
            dplyr::bind_rows(
              summariseConcept(cohort, tableWindow, strata, tablePrefix) |>
                dplyr::mutate(
                  "window_name" = names(window)[win],
                  "table_name" = .env$tab,
                  "analysis" = "source",
                  "type" = .env$type
                )
            )
        }
      }
    }
  }
  cli::cli_status_clear(id)

  # calculate denominators
  den <- denominatorCounts(cohort, x, strata, window, tablePrefix)

  # format results
  results <- lsc |>
    formatLscResult(den, cdm, minimumFrequency)

  # summarised_result format
  results <- results |>
    dplyr::mutate(
      "variable_name" = .data$variable,
      "estimate_name" = .data$estimate_type,
      "estimate_value" = .data$estimate,
      "estimate_type" = dplyr::if_else(
        .data$estimate_type == "count", "integer", "percentage"
      )
    ) |>
    dplyr::rename("concept_id" = "concept") |>
    visOmopResults::uniteAdditional(cols = c("concept_id")) |>
    dplyr::select(!c("estimate", "variable")) |>
    dplyr::select(dplyr::all_of(c(
      "cdm_name", "table_name", "type", "analysis",
      "group_name", "group_level", "strata_name", "strata_level",
      "variable_name", "variable_level", "estimate_name", "estimate_type",
      "estimate_value", "additional_name", "additional_level"
    )))

  sets <- results |>
    dplyr::select("table_name", "type", "analysis") |>
    dplyr::distinct() |>
    dplyr::mutate("result_id" = dplyr::row_number())

  results <- results |>
    dplyr::left_join(sets, by = c("table_name", "type", "analysis")) |>
    dplyr::select(-"table_name", -"type", -"analysis")

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
    dplyr::mutate(order_id2 = as.numeric(.data$additional_level)) |>
    dplyr::arrange(
      .data$result_id, .data$order_id, .data$order_id2, .data$estimate_name
    ) |>
    dplyr::select(!c("order_id", "order_id2"))
  # TO consider -> order by prevalence/percentage

  results <- results |>
    omopgenerics::newSummarisedResult(
      settings = sets |>
        dplyr::mutate(
          "result_type" = "summarise_large_scale_characteristics",
          "package_name" = "CohortCharacteristics",
          "package_version" = pkgVersion()
        )
    )

  # eliminate permanent tables
  cdm <- omopgenerics::dropTable(cdm = cdm, name = dplyr::starts_with(tablePrefix))

  # return
  return(results)
}

getAnalyses <- function(eventInWindow, episodeInWindow) {
  atc <- c("ATC 1st", "ATC 2nd", "ATC 3rd", "ATC 4th", "ATC 5th")
  icd10 <- c("icd10 chapter", "icd10 subchapter")
  list(
    dplyr::tibble(
      table = eventInWindow[!(eventInWindow %in% c(atc, icd10))],
      type = "event", analysis = "standard"
    ),
    dplyr::tibble(
      table = episodeInWindow[!(episodeInWindow %in% c(atc, icd10))],
      type = "episode", analysis = "standard"
    ),
    dplyr::tibble(
      table = "drug_exposure", type = "event",
      analysis = eventInWindow[eventInWindow %in% atc],
    ),
    dplyr::tibble(
      table = "drug_exposure", type = "episode",
      analysis = episodeInWindow[episodeInWindow %in% atc],
    ),
    dplyr::tibble(
      table = "condition_occurrence", type = "event",
      analysis = eventInWindow[eventInWindow %in% icd10],
    ),
    dplyr::tibble(
      table = "condition_occurrence", type = "episode",
      analysis = episodeInWindow[episodeInWindow %in% icd10],
    )
  ) |>
    dplyr::bind_rows() |>
    tidyr::drop_na()
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
    dplyr::compute(
      name = paste0(tablePrefix, "individuals"),
      temporary = FALSE,
      overwrite = TRUE
    )
  return(x)
}
getTable <- function(tab, x, includeSource, minWindow, maxWindow, tablePrefix, excludedCodes) {
  cdm <- omopgenerics::cdmReference(x)
  toSelect <- c(
    "subject_id" = "person_id",
    "start_diff" = PatientProfiles::startDateColumn(tab),
    "end_diff" = ifelse(
      is.na(PatientProfiles::endDateColumn(tab)),
      PatientProfiles::startDateColumn(tab),
      PatientProfiles::endDateColumn(tab)
    ),
    "standard" = PatientProfiles::standardConceptIdColumn(tab),
    "source" = PatientProfiles::sourceConceptIdColumn(tab)
  )
  if (includeSource == FALSE || is.na(PatientProfiles::sourceConceptIdColumn(tab))) {
    toSelect <- toSelect["source" != names(toSelect)]
  }
  table <- cdm[[tab]] |>
    dplyr::select(dplyr::all_of(toSelect)) |>
    dplyr::inner_join(x, by = "subject_id") |>
    dplyr::mutate(end_diff = dplyr::if_else(
      is.na(.data$end_diff), .data$start_diff, .data$end_diff
    )) %>% # to be removed
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
  if (length(excludedCodes) > 0) {
    nm <- paste0(tablePrefix, "concepts")
    cdm <- omopgenerics::insertTable(
      cdm = cdm, name = nm, table = dplyr::tibble("standard" = excludedCodes),
      overwrite = TRUE
    )
    cdm[[nm]] <- cdm[[nm]] |> dplyr::compute()
    table <- table |>
      dplyr::anti_join(cdm[[nm]], by = "standard")
    if ("source" %in% colnames(table)) {
      table <- table |>
        dplyr::anti_join(
          cdm[[nm]] |> dplyr::rename("source" = "standard"),
          by = "source"
        )
    }
  }
  table <- table |>
    dplyr::select(-"start_obs", -"end_obs") |>
    dplyr::compute(
      name = paste0(tablePrefix, "table"),
      temporary = FALSE,
      overwrite = TRUE
    )
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
        "obs_id", "concept", dplyr::all_of(unique(unlist(strata)))
      ) |>
      dplyr::compute(
        name = paste0(tablePrefix, "table_window_cohort"),
        temporary = FALSE,
        overwrite = TRUE
      )
    result <- result |>
      dplyr::bind_rows(
        tableWindowCohort |>
          dplyr::group_by(.data$concept) |>
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
          dplyr::group_by(dplyr::pick(c("concept", strata[[k]]))) |>
          dplyr::summarise(count = as.numeric(dplyr::n()), .groups = "drop") |>
          dplyr::collect() |>
          dplyr::filter(!is.na(!!as.symbol(strata[[k]]))) |>
          visOmopResults::uniteStrata(cols = strata[[k]])
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
formatLscResult <- function(lsc, den, cdm, minimumFrequency) {
  lsc <- lsc |>
    dplyr::inner_join(
      den |>
        dplyr::rename("denominator" = "count") |>
        dplyr::select(-"concept"),
      by = c(
        "strata_name", "strata_level", "group_name", "group_level",
        "window_name"
      )
    )

  start_rows <- nrow(lsc)
  lsc <- lsc |>
    dplyr::mutate(percentage = round(100 * .data$count / .data$denominator, 2)) |>
    dplyr::select(-"denominator") |>
    dplyr::filter(.data$percentage >= 100 * .env$minimumFrequency)
  end_rows <- nrow(lsc)

  if (end_rows < start_rows) {
    "{start_rows - end_rows} estimate{?s} dropped as frequency less than {paste0(minimumFrequency*100)}%" |>
      cli::cli_inform()
  }

  lsc <- lsc |>
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

  omopgenerics::dropTable(cdm = cdm, name = conceptsTblName)

  return(conceptNames)
}
getTableAnalysis <- function(table, type, analysis, tablePrefix) {
  if (type == "event") {
    table <- table |>
      dplyr::mutate("end_diff" = .data$start_diff)
  }
  if (analysis %in% c("standard", "source")) {
    table <- table |>
      dplyr::rename("concept" = dplyr::all_of(analysis)) |>
      dplyr::select(-dplyr::any_of(c("standard", "source")))
  } else {
    table <- table |>
      dplyr::rename("concept" = "standard") |>
      dplyr::select(-dplyr::any_of("source"))
    table <- getCodesGroup(table, analysis, tablePrefix)
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
    dplyr::select("subject_id", "cohort_start_date", "obs_id", "concept") |>
    dplyr::distinct() |>
    dplyr::compute(
      name = paste0(tablePrefix, "table_window"),
      temporary = FALSE,
      overwrite = TRUE
    )
  return(tableWindow)
}
trimCounts <- function(lsc, tableWindow, minimumCount, tablePrefix, winName) {
  x <- tableWindow |>
    dplyr::inner_join(
      tableWindow |>
        dplyr::group_by(.data$concept) |>
        dplyr::summarise(count = dplyr::n(), .groups = "drop") |>
        dplyr::filter(.data$count >= .env$minimumCount) |>
        dplyr::select("concept"),
      by = "concept"
    ) |>
    dplyr::mutate("window_name" = .env$winName)
  if (is.null(lsc)) {
    lsc <- x |>
      dplyr::compute(
        name = paste0(tablePrefix, "lsc"), temporary = FALSE, overwrite = TRUE
      )
  } else {
    lsc <- lsc |>
      dplyr::union_all(x) |>
      dplyr::compute(
        name = paste0(tablePrefix, "lsc"), temporary = FALSE, overwrite = TRUE
      )
  }
  return(lsc)
}
