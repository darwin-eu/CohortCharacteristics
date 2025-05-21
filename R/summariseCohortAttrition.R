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

#' Summarise attrition associated with cohorts in a cohort table
#'
#' @inheritParams cohortDoc
#' @inheritParams cohortIdDoc
#'
#' @export
#'
#' @return  A summary of the attrition for the cohorts in the cohort table.
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' cdm <- mockCohortCharacteristics()
#'
#' summariseCohortAttrition(cohort = cdm$cohort1) |>
#'   glimpse()
#'
#' mockDisconnect(cdm)
#' }
summariseCohortAttrition <- function(cohort,
                                     cohortId = NULL) {
  cohort <- omopgenerics::validateCohortArgument(cohort)
  cohortId <- omopgenerics::validateCohortIdArgument(cohortId, cohort)

  set <- omopgenerics::settings(cohort) |>
    dplyr::filter(.data$cohort_definition_id %in% .env$cohortId) |>
    dplyr::mutate("result_id" = as.integer(dplyr::row_number()))

  attritionSummary <- omopgenerics::attrition(cohort) |>
    summariseAttrition(
      set, omopgenerics::tableName(cohort), omopgenerics::cdmName(cohort)
    )

  return(attritionSummary)
}

summariseAttrition <- function(att,
                               set = NULL,
                               tname = "unknown",
                               cname = "unknown") {
  if (is.null(set)) {
    set <- att |>
      dplyr::select("cohort_definition_id") |>
      dplyr::distinct() |>
      dplyr::mutate(
        "result_id" = .data$cohort_definition_id,
        "cohort_name" = paste0("unknown_", .data$cohort_definition_id)
      )
  }
  att |>
    dplyr::inner_join(
      set |>
        dplyr::select("cohort_definition_id", "result_id", "cohort_name"),
      by = "cohort_definition_id"
    ) |>
    dplyr::select(-"cohort_definition_id") |>
    dplyr::mutate(dplyr::across(!"result_id", as.character)) |>
    tidyr::pivot_longer(
      cols = c(
        "number_records", "number_subjects", "excluded_records",
        "excluded_subjects"
      ),
      names_to = "variable_name",
      values_to = "estimate_value"
    ) |>
    dplyr::mutate(
      "estimate_name" = "count",
      "variable_level" = NA_character_,
      "estimate_type" = "integer",
      "cdm_name" = cname
    ) |>
    omopgenerics::uniteGroup("cohort_name") |>
    omopgenerics::uniteStrata("reason") |>
    omopgenerics::uniteAdditional("reason_id") |>
    orderSummaryAttrition() |>
    omopgenerics::newSummarisedResult(
      settings = set |>
        dplyr::select(!"cohort_name") |>
        dplyr::mutate(
          "result_type" = "summarise_cohort_attrition",
          "package_name" = "CohortCharacteristics",
          "package_version" = pkgVersion(),
          "table_name" = tname
        ) |>
        dplyr::relocate(dplyr::all_of(c(
          "result_id", "result_type", "package_name", "package_version"
        ))) |>
        dplyr::mutate(
          cohort_definition_id = as.character(.data$cohort_definition_id)
        )
    )
}
orderSummaryAttrition <- function(x) {
  vars <- c(
    "number_records", "number_subjects", "excluded_records", "excluded_subjects"
  )
  x |>
    dplyr::mutate(additional_level = as.numeric(.data$additional_level)) |>
    dplyr::inner_join(
      dplyr::tibble(variable_name = vars, var_id = seq_along(vars)),
      by = "variable_name"
    ) |>
    dplyr::arrange(.data$result_id, .data$additional_level, .data$var_id) |>
    dplyr::select(!"var_id") |>
    dplyr::mutate(additional_level = as.character(.data$additional_level))
}
