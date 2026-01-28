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

#' Summarise timing between entries into cohorts in a cohort table
#'
#' @inheritParams cohortDoc
#' @inheritParams cohortIdDoc
#' @inheritParams strataDoc
#' @param restrictToFirstEntry If TRUE only an individual's first entry per
#' cohort will be considered. If FALSE all entries per individual will be
#' considered.
#' @param estimates Summary statistics to use when summarising timing.
#' @param density deprecated.
#'
#' @return A summary of timing between entries into cohorts in the cohort table.
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' cdm <- mockCohortCharacteristics(numberIndividuals = 100)
#'
#' summariseCohortTiming(cdm$cohort2) |>
#'   glimpse()
#'
#' }
#'
summariseCohortTiming <- function(cohort,
                                  cohortId = NULL,
                                  strata = list(),
                                  restrictToFirstEntry = TRUE,
                                  estimates = c("min", "q25", "median", "q75", "max", "density"),
                                  density = lifecycle::deprecated()) {
  if (lifecycle::is_present(density)) {
    lifecycle::deprecate_soft(
      when = "0.3.0", what = "summariseCohortTiming(density = )",
      details = "Please include 'density' in the estimates vector instead."
    )
    if (density) estimates <- unique(c(estimates, "density"))
  }
  # validate inputs
  cohort <- omopgenerics::validateCohortArgument(cohort)
  cohortId <- omopgenerics::validateCohortIdArgument(cohortId, cohort)
  omopgenerics::assertNumeric(cohortId, null = TRUE)
  strata <- omopgenerics::validateStrataArgument(strata = strata, table = cohort)
  omopgenerics::assertTrue(all(c("cohort_definition_id", "subject_id", "cohort_start_date", "cohort_end_date") %in% colnames(cohort)))
  omopgenerics::assertLogical(restrictToFirstEntry, length = 1)
  omopgenerics::assertCharacter(estimates)
  timing <- estimates

  # ---- if no timing estimates requested, return empty result with settings ----
  if (length(timing) == 0) {
    cli::cli_inform("No timing estimates requested: returning empty summarised timing result.")
    return(.buildEmptySummariseCohortTimingResult(
      restrictToFirstEntry = restrictToFirstEntry
    ))
  }

  # ---- if cohort table is empty before any filtering ----
  if (omopgenerics::isTableEmpty(cohort)) {
    cli::cli_inform("Cohort table is empty: returning empty summarised timing result.")
    return(.buildEmptySummariseCohortTimingResult(
      restrictToFirstEntry = restrictToFirstEntry
    ))
  }

  cohort <- cohort |>
    PatientProfiles::filterCohortId(cohortId = cohortId) |>
    PatientProfiles::addCohortName()

  # ---- if table becomes empty after filtering by cohortId ----
  if (omopgenerics::isTableEmpty(cohort)) {
    cli::cli_inform("Empty cohort table after filtering by cohortId: returning empty summarised timing result.")
    return(.buildEmptySummariseCohortTimingResult(
      restrictToFirstEntry = restrictToFirstEntry
    ))
  }

  if (isTRUE(restrictToFirstEntry)) {
    cohort <- cohort |>
      dplyr::group_by(.data$subject_id, .data$cohort_definition_id) |>
      dplyr::filter(.data$cohort_start_date == min(.data$cohort_start_date, na.rm = TRUE)) |>
      dplyr::ungroup()
  }

  strataCols <- unlist(strata) |> unique()
  # should we use addCohortIntersectDate instead to avoid potentially large number of rows?
  cohort_timings <- cohort |>
    dplyr::rename("cohort_name_reference" = "cohort_name") |>
    dplyr::select(dplyr::all_of(c(
      strataCols, "cohort_name_reference",
      "cohort_start_date", "cohort_end_date",
      "subject_id"
    ))) |>
    dplyr::inner_join(
      cohort |>
        dplyr::rename_with(~ paste0(.x, "_comparator"),
          .cols = c(
            "cohort_definition_id", "cohort_start_date",
            "cohort_end_date", "cohort_name"
          )
        ) |>
        dplyr::select(dplyr::all_of(c(
          strataCols, "cohort_name_comparator",
          "cohort_start_date_comparator", "cohort_end_date_comparator",
          "subject_id"
        ))),
      by = c("subject_id", strataCols)
    ) |>
    dplyr::filter(.data$cohort_name_reference != .data$cohort_name_comparator) %>% # to be removed
    dplyr::mutate(days_between_cohort_entries = as.integer(clock::date_count_between(
      start = .data$cohort_start_date,
      end = .data$cohort_start_date_comparator,
      precision = "day"
    ))) |>
    dplyr::select(!c(
      "cohort_start_date", "cohort_end_date", "cohort_start_date_comparator",
      "cohort_end_date_comparator"
    )) |>
    dplyr::collect()

  if (nrow(cohort_timings) == 0) {
    return(omopgenerics::emptySummarisedResult())
  }

  result <- cohort_timings |>
    PatientProfiles::summariseResult(
      group = c("cohort_name_reference", "cohort_name_comparator"),
      includeOverallGroup = FALSE,
      strata = strata,
      includeOverallStrata = TRUE,
      variables = "days_between_cohort_entries",
      estimates = timing
    ) |>
    dplyr::mutate("cdm_name" = omopgenerics::cdmName(cohort))

  # get all combinations
  group <- settings(cohort) |>
    dplyr::filter(.data$cohort_definition_id %in% .env$cohortId) |>
    dplyr::pull("cohort_name") |>
    getCohortComp()
  strata <- getStratas(cohort, strata)
  if ("density" %in% estimates) {
    estimates <- c(estimates[estimates != "density"], "density_x", "density_y")
  }
  combinations <- getCombinations(
    group,
    strata,
    dplyr::tibble(
      variable_name = c("number records", "number subjects"),
      estimate_name = "count"
    ) |>
      dplyr::union_all(dplyr::tibble(
        variable_name = "days_between_cohort_entries",
        estimate_name = estimates
      ))
  ) |>
    dplyr::mutate(order_id = dplyr::row_number())
  result <- result |>
    dplyr::left_join(
      combinations,
      by = c(
        "group_name", "group_level", "strata_name", "strata_level",
        "variable_name", "estimate_name"
      )
    ) |>
    dplyr::arrange(.data$order_id, .data$variable_level) |>
    dplyr::select(!"order_id")

  result <- result |>
    omopgenerics::newSummarisedResult(settings = dplyr::tibble(
      "result_id" = 1L,
      "package_name" = "CohortCharacteristics",
      "package_version" = pkgVersion(),
      "result_type" = "summarise_cohort_timing",
      "restrict_to_first_entry" = as.character(restrictToFirstEntry)
    ))

  return(result)
}

getCohortComp <- function(cohortNames) {
  tidyr::expand_grid(
    cohort_name_reference = cohortNames, cohort_name_comparator = cohortNames
  ) |>
    dplyr::filter(.data$cohort_name_reference != .data$cohort_name_comparator) |>
    omopgenerics::uniteGroup(
      cols = c("cohort_name_reference", "cohort_name_comparator")
    )
}
getStratas <- function(data, strata) {
  res <- purrr::map(strata, \(x) {
    data |>
      dplyr::select(dplyr::all_of(x)) |>
      dplyr::distinct() |>
      dplyr::collect() |>
      dplyr::arrange(dplyr::across(dplyr::everything())) |>
      omopgenerics::uniteStrata(cols = x)
  }) |>
    dplyr::bind_rows()
  dplyr::tibble(strata_name = "overall", strata_level = "overall") |>
    dplyr::bind_rows(res)
}
getCombinations <- function(...) {
  x <- list(...)
  opts <- list()
  ids <- omopgenerics::uniqueId(length(x), nChar = 1)
  for (k in seq_along(x)) {
    x[[k]] <- x[[k]] |>
      dplyr::mutate(!!ids[k] := dplyr::row_number())
    opts[[ids[k]]] <- x[[k]][[ids[k]]]
  }

  combinations <- do.call(tidyr::expand_grid, opts)

  for (k in seq_along(x)) {
    combinations <- combinations |>
      dplyr::left_join(x[[k]], by = ids[k]) |>
      dplyr::select(!dplyr::all_of(ids[k]))
  }

  return(combinations)
}
sortWindow <- function(window) {
  window |>
    purrr::imap(\(x, idx) dplyr::tibble(
      window_name = idx, first = x[1], second = x[2]
    )) |>
    dplyr::bind_rows() |>
    dplyr::arrange(.data$first, .data$second) |>
    dplyr::pull("window_name")
}

.buildEmptySummariseCohortTimingResult <- function(restrictToFirstEntry) {
  settings <- dplyr::tibble(
    result_id = 1L,
    package_name = "CohortCharacteristics",
    package_version = pkgVersion(),
    result_type = "summarise_cohort_timing",
    restrict_to_first_entry = as.character(restrictToFirstEntry)
  )

  x <- omopgenerics::emptySummarisedResult(settings = settings)

  return(x)
}
