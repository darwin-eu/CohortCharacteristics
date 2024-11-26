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

#' Format a summarise_large_scale_characteristics object into a visual table.
#'
#' `r lifecycle::badge("experimental")`
#'
#' @inheritParams resultDoc
#' @param topConcepts Number of concepts to restrict the table.
#' @inheritParams tableDoc
#'
#' @return A formatted table.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(duckdb)
#' library(CDMConnector)
#'
#' con <- dbConnect(duckdb(), eunomiaDir())
#' cdm <- cdmFromCon(con = con, cdmSchema = "main", writeSchema = "main")
#' cdm <- generateConceptCohortSet(
#'   cdm = cdm,
#'   conceptSet = list("viral_pharyngitis" = 4112343),
#'   name = "my_cohort"
#' )
#'
#' result <- summariseLargeScaleCharacteristics(
#'   cohort = cdm$my_cohort,
#'   eventInWindow = "condition_occurrence",
#'   episodeInWindow = "drug_exposure"
#' )
#'
#' tableLargeScaleCharacteristics(result)
#'
#' cdmDisconnect(cdm)
#' }
#'
tableLargeScaleCharacteristics <- function(result,
                                           topConcepts = NULL,
                                           type = "gt",
                                           header = c("cdm_name", "cohort_name", strataColumns(result), "variable_level"),
                                           groupColumn = c("table_name", "type", "analysis"),
                                           hide = character()) {
  omopgenerics::assertNumeric(topConcepts, integerish = TRUE, min = 1, null = TRUE, length = 1)
  result |>
    tableCohortCharacteristics(
      resultType = "summarise_large_scale_characteristics",
      header = header,
      groupColumn = groupColumn,
      hide = hide,
      rename = c("CDM name" = "cdm_name"),
      modifyResults = \(x, ...) {
        if (!is.null(topConcepts)) {
          top <- x |>
            dplyr::filter(.data$estimate_name == "count") |>
            dplyr::mutate(estimate_value = as.numeric(.data$estimate_value)) |>
            dplyr::group_by(.data$variable_name) |>
            dplyr::summarise(max = max(.data$estimate_value)) |>
            dplyr::arrange(dplyr::desc(.data$max)) |>
            utils::head(topConcepts) |>
            dplyr::select("variable_name")
          x |>
            dplyr::inner_join(top, by = "variable_name")
        }
        return(x)
      },
      estimateName = c("N (%)" = "<count> (<percentage> %)"),
      type = type
    )
}
