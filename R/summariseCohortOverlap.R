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

#' Summarise overlap between cohorts in a cohort table
#'
#' @inheritParams cohortDoc
#' @inheritParams cohortIdDoc
#' @inheritParams strataDoc
#' @param overlapBy Columns in cohort to use as record identifiers.
#'
#' @return  A summary of overlap between cohorts in the cohort table.
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' cdm <- mockCohortCharacteristics()
#'
#' summariseCohortOverlap(cdm$cohort2) |>
#'   glimpse()
#'
#' }
summariseCohortOverlap <- function(cohort,
                                   cohortId = NULL,
                                   strata = list(),
                                   overlapBy = "subject_id") {
  # validate inputs
  cohort <- omopgenerics::validateCohortArgument(cohort)
  cohortId <- omopgenerics::validateCohortIdArgument({{cohortId}}, cohort)
  omopgenerics::assertCharacter(overlapBy)
  omopgenerics::assertTable(cohort, class = "cohort_table", columns = overlapBy)
  if (length(overlapBy) == 0) {
    cli::cli_abort("{.var overlapBy} can not be empty.")
  }
  strata <- omopgenerics::validateStrataArgument(strata = strata, table = cohort)

  # permanent table
  name <- omopgenerics::tableName(cohort)
  if (is.na(name)) {
    cli::cli_abort("Please provide a permanent cohort table.")
  }

  # needed to report all cohorts
  cohortNames <- omopgenerics::settings(cohort) |>
    dplyr::filter(.data$cohort_definition_id %in% .env$cohortId) |>
    dplyr::pull("cohort_name")

  tmpName <- omopgenerics::uniqueTableName(omopgenerics::tmpPrefix())

  strataCols <- unique(unlist(strata))

  # initial table
  cohort <- PatientProfiles::filterCohortId(cohort = cohort, cohortId = cohortId)

  # return empty cohort summarise Result if cohort table is empty
  if(omopgenerics::isTableEmpty(cohort)){
    cli::cli_inform("Cohort table is empty: returning empty summarised result.")
    return(.buildEmptySummariseResultsOverlap(overlapBy = overlapBy))
  }

  cohort <- cohort |>
    PatientProfiles::addCohortName() |>
    PatientProfiles::filterCohortId(cohortId = cohortId) |>
    dplyr::select(dplyr::all_of(c("cohort_name", overlapBy, strataCols))) |>
    dplyr::distinct() |>
    dplyr::compute(name = tmpName, temporary = FALSE)

  # return empty cohort summarise Result if cohort table is empty after filter
  if(omopgenerics::isTableEmpty(cohort)){
    cli::cli_inform("Empty cohort table after filtering by cohortId: returning empty summarised result")
    return(.buildEmptySummariseResultsOverlap(overlapBy = overlapBy))
  }

  # create a unique_id
  if (length(overlapBy) > 1) {
    col <- omopgenerics::uniqueId(n = 1, exclude = colnames(cohort))
    cohort <- cohort |>
      dplyr::left_join(
        cohort |>
          dplyr::select(dplyr::all_of(overlapBy)) |>
          dplyr::distinct() |>
          dplyr::arrange(dplyr::across(dplyr::all_of(overlapBy))) |>
          dplyr::mutate(!!col := dplyr::row_number()),
        by = overlapBy
      ) |>
      dplyr::select(dplyr::all_of(c(col, "cohort_name", strataCols))) |>
      dplyr::compute(name = tmpName, temporary = FALSE)
  } else {
    col <- overlapBy
  }

  var <- ifelse(identical(overlapBy, "subject_id"), "subjects", "records")

  strata <- c(list(character()), strata)

  result <- strata |>
    purrr::map(\(strataCols) {
      counts <- cohort |>
        dplyr::group_by(dplyr::across(dplyr::all_of(c("cohort_name", strataCols)))) |>
        dplyr::summarise(
          number_subjects = dplyr::n_distinct(.data[[col]]),
          .groups = "drop"
        ) |>
        dplyr::collect()

      cohortDistinct <- cohort |>
        dplyr::distinct(dplyr::across(dplyr::all_of(c(
          col, "cohort_name", strataCols
        ))))

      colsOverlap <- c("cohort_name_reference", "cohort_name_comparator", strataCols)

      overlap <- cohortDistinct |>
        dplyr::rename("cohort_name_reference" = "cohort_name") |>
        dplyr::inner_join(
          cohortDistinct |>
            dplyr::rename("cohort_name_comparator" = "cohort_name"),
          by = c(col, strataCols)
        ) |>
        dplyr::group_by(dplyr::across(dplyr::all_of(colsOverlap))) |>
        dplyr::summarise(
          "number_subjects_overlap" = dplyr::n_distinct(.data[[col]]),
          .groups = "drop"
        ) |>
        dplyr::collect()

      strataColsValues <- overlap |>
        dplyr::select(dplyr::all_of(strataCols)) |>
        purrr::map(\(x) as.character(sort(unique(x))))

      tidyr::expand_grid(
        cohort_name_reference = cohortNames,
        cohort_name_comparator = cohortNames,
        !!!strataColsValues
      ) |>
        dplyr::filter(.data$cohort_name_reference != .data$cohort_name_comparator) |>
        dplyr::left_join(overlap, by = colsOverlap) |>
        dplyr::left_join(
          counts |>
            dplyr::rename(
              "cohort_name_reference" = "cohort_name",
              "number_subjects_reference" = "number_subjects"
            ),
          by = c("cohort_name_reference", strataCols)
        ) |>
        dplyr::left_join(
          counts |>
            dplyr::rename(
              "cohort_name_comparator" = "cohort_name",
              "number_subjects_comparator" = "number_subjects"
            ),
          by = c("cohort_name_comparator", strataCols)
        ) |>
        dplyr::mutate(dplyr::across(
          c("number_subjects_overlap", "number_subjects_reference",
            "number_subjects_comparator"),
          \(x) dplyr::coalesce(as.integer(x), 0L)
        )) |>
        getOverlapEstimates() |>
        dplyr::mutate(variable_level = .env$var) |>
        omopgenerics::uniteGroup(cols = c("cohort_name_reference", "cohort_name_comparator")) |>
        omopgenerics::uniteStrata(cols = strataCols) |>
        omopgenerics::uniteAdditional(cols = character()) |>
        dplyr::mutate(result_id = 1L, cdm_name = omopgenerics::cdmName(cohort))
    }) |>
    dplyr::bind_rows() |>
    dplyr::mutate(
      variable_name = dplyr::case_when(
        .data$variable_name == "reference" ~ "Only in reference cohort",
        .data$variable_name == "comparator" ~ "Only in comparator cohort",
        .data$variable_name == "overlap" ~ "In both cohorts",
      ),
      variable_level = stringr::str_to_sentence(.data$variable_level)
    ) |>
    omopgenerics::newSummarisedResult(settings = dplyr::tibble(
      result_id = 1L,
      result_type = "summarise_cohort_overlap",
      package_name = "CohortCharacteristics",
      package_version = pkgVersion(),
      overlap_by = paste0(.env$overlapBy, collapse = "; ")
    ))

  cdm <- omopgenerics::cdmReference(cohort)
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(tmpName))

  return(result)
}

getOverlapEstimates <- function(x) {
  # overlap counts and percentages
  x <- x |>
    dplyr::mutate(
      number_subjects_reference = .data$number_subjects_reference - .data$number_subjects_overlap,
      number_subjects_comparator = .data$number_subjects_comparator - .data$number_subjects_overlap
    )
  x |>
    dplyr::relocate(c("number_subjects_reference", "number_subjects_overlap", "number_subjects_comparator")) |>
    tidyr::pivot_longer(cols = dplyr::starts_with("number"), names_to = "variable_name", values_to = "estimate_value") |>
    dplyr::mutate(
      variable_name = gsub("number_subjects_", "", .data$variable_name),
      estimate_name = "count",
      estimate_type = "integer",
      estimate_value = as.character(.data$estimate_value)
    ) |>
    dplyr::union_all(
      x |>
        dplyr::mutate(total_subjects = .data$number_subjects_comparator + .data$number_subjects_reference + .data$number_subjects_overlap) |>
        dplyr::mutate(dplyr::across(
          .cols = dplyr::all_of(c("number_subjects_reference", "number_subjects_overlap", "number_subjects_comparator")),
          .fns = \(x) x / .data$total_subjects * 100
        )) |>
        dplyr::select(!dplyr::all_of(c("total_subjects"))) |>
        tidyr::pivot_longer(cols = dplyr::starts_with("number"), names_to = "variable_name", values_to = "estimate_value") |>
        dplyr::mutate(
          variable_name = gsub("number_subjects_", "", .data$variable_name),
          estimate_name = "percentage",
          estimate_type = "percentage",
          estimate_value = as.character(.data$estimate_value)
        )
    )
}

.buildEmptySummariseResultsOverlap <- function(cohort, overlapBy = "subject_id") {
  settings <- dplyr::tibble(
    result_id = 1L,
    result_type = "summarise_cohort_overlap",
    package_name = "CohortCharacteristics",
    package_version = pkgVersion(),
    group = "cohort_name_reference &&& cohort_name_comparator",
    overlap_by = paste0(overlapBy, collapse = "; ")
  )

  x <- omopgenerics::emptySummarisedResult(settings = settings)

  return(x)

}

