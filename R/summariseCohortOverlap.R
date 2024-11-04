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
#' @param cohort A cohort table in the cdm.
#' @param cohortId A cohort definition id to restrict by. If NULL, all cohorts
#' will be included.
#' @param strata A list of variables to stratify results. These variables
#' must have been added as additional columns in the cohort table.
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
#' mockDisconnect(cdm)
#' }
summariseCohortOverlap <- function(cohort,
                                   cohortId = NULL,
                                   strata = list()) {
  # validate inputs
  cohort <- omopgenerics::validateCohortArgument(cohort)
  cohortId <- omopgenerics::validateCohortIdArgument(cohortId, cohort)
  checkStrata(strata, cohort)

  # permanent table
  name <- omopgenerics::tableName(cohort)
  if (is.na(name)) {
    cli::cli_abort("Please provide a permanent cohort table.")
  }

  ids <- cohort |>
    omopgenerics::settings() |>
    dplyr::pull(.data$cohort_definition_id)

  if (is.null(cohortId)) {
    cohortId <- ids
  } else {
    indNot <- which(!cohortId %in% ids)
    if (length(indNot) > 0) {
      cli::cli_warn("{cohortId[indNot]} {?is/are} not in the cohort table.")
    }
  }

  prefix <- omopgenerics::tmpPrefix()

  cohort <- PatientProfiles::addCohortName(cohort) |>
    dplyr::filter(.data$cohort_definition_id %in% .env$cohortId) |>
    dplyr::compute(
      name = omopgenerics::uniqueTableName(prefix), temporary = FALSE
    )

  overlapOverallData <- cohort |>
    dplyr::distinct(.data$subject_id, .data$cohort_name) |>
    dplyr::rename("cohort_name_reference" = "cohort_name") |>
    dplyr::select(dplyr::all_of(c("subject_id", "cohort_name_reference"))) |>
    dplyr::inner_join(
      cohort |>
        dplyr::distinct(.data$subject_id, .data$cohort_name) |>
        dplyr::rename("cohort_name_comparator" = "cohort_name") |>
        dplyr::select(dplyr::all_of(c("subject_id", "cohort_name_comparator"))),
      by = "subject_id"
    ) |>
    dplyr::compute(
      name = omopgenerics::uniqueTableName(prefix), temporary = FALSE
    )

  # overall
  cohort_counts <- omopgenerics::cohortCount(cohort) |>
    dplyr::inner_join(omopgenerics::settings(cohort),
      by = "cohort_definition_id"
    ) |>
    dplyr::select("cohort_name", "number_subjects")
  # get inner join counts
  overlap <- overlapOverallData |>
    dplyr::group_by(
      .data$cohort_name_reference,
      .data$cohort_name_comparator
    ) |>
    dplyr::summarise(
      "number_subjects_overlap" = dplyr::n(),
      .groups = "drop"
    ) |>
    dplyr::collect() |>
    dplyr::filter(.data$cohort_name_reference != .data$cohort_name_comparator) |>
    dplyr::left_join(cohort_counts |> dplyr::rename_with(~ paste0(.x, "_reference")), by = "cohort_name_reference") |>
    dplyr::left_join(cohort_counts |> dplyr::rename_with(~ paste0(.x, "_comparator")), by = "cohort_name_comparator")

  # overlap counts and percentages
  overlap <- overlap |>
    getOverlapEstimates() |>
    visOmopResults::uniteGroup(cols = c("cohort_name_reference", "cohort_name_comparator")) |>
    visOmopResults::uniteStrata(cols = character())

  # strata
  if (!is.null(unlist(strata))) {
    overlapStrataData <- cohort |>
      dplyr::distinct(dplyr::across(dplyr::all_of(c("subject_id", "cohort_name", unique(unlist(strata)))))) |>
      dplyr::rename("cohort_name_reference" = "cohort_name") |>
      dplyr::select(dplyr::all_of(c("subject_id", "cohort_name_reference", unique(unlist(strata))))) |>
      dplyr::inner_join(
        cohort |>
          dplyr::distinct(dplyr::across(dplyr::all_of(c("subject_id", "cohort_name", unique(unlist(strata)))))) |>
          dplyr::rename("cohort_name_comparator" = "cohort_name") |>
          dplyr::select(dplyr::all_of(c("subject_id", "cohort_name_comparator", unique(unlist(strata))))),
        by = c("subject_id", unique(unlist(strata)))
      ) |>
      dplyr::compute(
        name = omopgenerics::uniqueTableName(prefix), temporary = FALSE
      )

    overlap <- overlap |>
      dplyr::union_all(
        lapply(
          strata,
          function(strataName, data = overlapStrataData) {
            overlap.strata <- data |>
              dplyr::group_by(dplyr::across(dplyr::all_of(
                c("cohort_name_reference", "cohort_name_comparator", strataName)
              ))) |>
              dplyr::summarise(
                "number_subjects" = dplyr::n(),
                .groups = "drop"
              ) |>
              dplyr::collect()
            cohort_counts.strata <- overlap.strata |>
              dplyr::filter(.data$cohort_name_reference == .data$cohort_name_comparator) |>
              dplyr::rename("cohort_name" = "cohort_name_reference") |>
              dplyr::select(!"cohort_name_comparator")
            overlap.strata <- overlap.strata |>
              dplyr::filter(.data$cohort_name_reference != .data$cohort_name_comparator) |>
              dplyr::rename_with(.fn = ~ paste0(.x, "_overlap"), .cols = dplyr::starts_with("number")) |>
              dplyr::left_join(
                cohort_counts.strata |>
                  dplyr::rename_with(
                    .fn = ~ paste0(.x, "_reference"),
                    .cols = dplyr::all_of(c("cohort_name", "number_subjects"))
                  ),
                by = c("cohort_name_reference", strataName)
              ) |>
              dplyr::left_join(
                cohort_counts.strata |>
                  dplyr::rename_with(
                    .fn = ~ paste0(.x, "_comparator"),
                    .cols = dplyr::all_of(c("cohort_name", "number_subjects"))
                  ),
                by = c("cohort_name_comparator", strataName)
              )
            overlap.strata <- overlap.strata |>
              getOverlapEstimates() |>
              visOmopResults::uniteGroup(cols = c("cohort_name_reference", "cohort_name_comparator")) |>
              visOmopResults::uniteStrata(cols = strataName) |>
              dplyr::select(dplyr::all_of(c(
                "group_name", "group_level", "strata_name", "strata_level", "variable_name",
                "variable_level", "estimate_name", "estimate_type", "estimate_value"
              )))
            return(overlap.strata)
          }
        ) |>
          dplyr::bind_rows()
      )
  }

  # report even if there is no overlap (number = 0):
  names <- cohort |>
    omopgenerics::settings() |>
    dplyr::filter(.data$cohort_definition_id %in% .env$cohortId) |>
    dplyr::pull(.data$cohort_name)
  combinations <- tidyr::expand_grid(
    cohort_name_reference = names,
    cohort_name_comparator = names
  ) |>
    dplyr::filter(.data$cohort_name_reference != .data$cohort_name_comparator) |>
    visOmopResults::uniteGroup(cols = c("cohort_name_reference", "cohort_name_comparator")) |>
    dplyr::mutate(strata_name = "overall", strata_level = "overall")

  if (length(strata) > 0) {
    combinations <- combinations |>
      dplyr::bind_rows(
        lapply(strata, function(strataCols, data = overlapStrataData) {
          data |>
            dplyr::select(dplyr::all_of(strataCols)) |>
            dplyr::distinct() |>
            dplyr::collect() |>
            dplyr::arrange(dplyr::across(dplyr::everything())) |>
            visOmopResults::uniteStrata(cols = strataCols)
        }) |>
          dplyr::bind_rows() |>
          dplyr::cross_join(
            combinations |> dplyr::select(-"strata_name", -"strata_level")
          )
      )
  }

  noOverlap <- combinations |>
    dplyr::anti_join(
      overlap |>
        dplyr::distinct(.data$group_name, .data$group_level, .data$strata_name, .data$strata_level),
      by = c("group_name", "group_level", "strata_name", "strata_level")
    )

  if (nrow(noOverlap) > 0) {
    overlap <- overlap |>
      dplyr::union(
        noOverlap |>
          dplyr::cross_join(
            tidyr::expand_grid(
              variable_name = c("reference", "comparator", "overlap"),
              variable_level = "number_subjects",
              estimate_name = c("count", "percentage"),
              estimate_value = "0"
            ) |>
              dplyr::mutate(estimate_type = dplyr::if_else(.data$estimate_name == "count", "integer", "percentage"))
          )
      )
  }

  overlap <- overlap |>
    dplyr::left_join(
      combinations |>
        dplyr::mutate(order_id = dplyr::row_number()),
      by = c("group_name", "group_level", "strata_name", "strata_level")
    ) |>
    dplyr::arrange(.data$order_id) |>
    dplyr::select(!"order_id") |>
    dplyr::mutate(
      result_id = as.integer(1),
      cdm_name = omopgenerics::cdmName(cohort),
      additional_name = "overall",
      additional_level = "overall",
      variable_level = dplyr::if_else(
        .data$variable_level == "reference" | .data$variable_level == "comparator",
        paste0("only_in_", .data$variable_level), .data$variable_level
      )
    ) |>
    omopgenerics::newSummarisedResult(
      settings = dplyr::tibble(
        result_id = 1L,
        result_type = "summarise_cohort_overlap",
        package_name = "CohortCharacteristics",
        package_version = as.character(utils::packageVersion("CohortCharacteristics"))
      )
    )

  cdm <- omopgenerics::cdmReference(cohort)
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::starts_with(prefix))

  return(overlap)
}

getOverlapEstimates <- function(x) {
  # overlap counts and percentages
  x |>
    dplyr::mutate(
      number_subjects_reference = .data$number_subjects_reference - .data$number_subjects_overlap,
      number_subjects_comparator = .data$number_subjects_comparator - .data$number_subjects_overlap
    ) |>
    tidyr::pivot_longer(cols = dplyr::starts_with("number"), names_to = "variable_name", values_to = "estimate_value") |>
    dplyr::mutate(
      variable_level = gsub("_overlap|_reference|_comparator", "", .data$variable_name),
      variable_name = gsub("number_subjects_", "", .data$variable_name),
      estimate_name = "count",
      estimate_type = "integer",
      estimate_value = as.character(.data$estimate_value)
    ) |>
    dplyr::union_all(
      x |>
        dplyr::mutate(
          total_subjects = .data$number_subjects_comparator + .data$number_subjects_reference - .data$number_subjects_overlap,
          number_subjects_reference = (.data$number_subjects_reference - .data$number_subjects_overlap) / (.data$total_subjects) * 100,
          number_subjects_comparator = (.data$number_subjects_comparator - .data$number_subjects_overlap) / (.data$total_subjects) * 100,
          number_subjects_overlap = .data$number_subjects_overlap / (.data$total_subjects) * 100
        ) |>
        dplyr::select(!dplyr::all_of(c("total_subjects"))) |>
        tidyr::pivot_longer(cols = dplyr::starts_with("number"), names_to = "variable_name", values_to = "estimate_value") |>
        dplyr::mutate(
          variable_level = gsub("_overlap|_reference|_comparator", "", .data$variable_name),
          variable_name = gsub("number_subjects_", "", .data$variable_name),
          estimate_name = "percentage",
          estimate_type = "percentage",
          estimate_value = as.character(.data$estimate_value)
        )
    )
}
