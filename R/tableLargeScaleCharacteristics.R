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

#' Visualise the top concepts per each cdm name, cohort, statification and
#' window.
#'
#' @inheritParams resultDoc
#' @inheritParams tableDoc
#' @param topConcepts Number of concepts to restrict the table.
#' @param type Type of table, it can be any of the supported
#' `visOmopResults::tableType()` formats.
#'
#' @return A formated table.
#' @export
#'
#' @examples
#' \dontrun{
#' library(CohortCharacteristics)
#' library(omock)
#' libarry(CDMConnector)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#'
#' cdm <- generateConceptCohortSet(
#'   cdm = cdm,
#'   conceptSet = list(viral_pharyngitis = 4112343),
#'   name = "my_cohort"
#' )
#'
#' result <- summariseLargeScaleCharacteristics(
#'   cohort = cdm$my_cohort,
#'   window = list(c(-Inf, -1), c(0, 0), c(1, Inf)),
#'   episodeInWindow = "drug_exposure"
#' )
#'
#' tableTopLargeScaleCharacteristics(result)
#'
#' cdmDisconnect(cdm)
#' }
#'
tableTopLargeScaleCharacteristics <- function(result,
                                              topConcepts = 10,
                                              type = NULL,
                                              style = NULL) {
  rlang::check_installed("visOmopResults")

  # check input
  result <- omopgenerics::validateResultArgument(result) |>
    omopgenerics::filterSettings(.data$result_type == "summarise_large_scale_characteristics")
  topConcepts <- as.integer(topConcepts)
  omopgenerics::assertNumeric(topConcepts, integerish = TRUE, length = 1, min = 1)
  type <- validateType(type)

  # create table
  x <- result |>
    omopgenerics::tidy() |>
    dplyr::group_by(dplyr::across(!dplyr::any_of(c(
      "variable_name", "concept_id", "count", "percentage", "source_concept_id",
      "source_concept_name"
    )))) |>
    dplyr::arrange(dplyr::desc(.data$percentage)) |>
    dplyr::slice_head(n = topConcepts) |>
    dplyr::mutate("top" = dplyr::row_number()) |>
    dplyr::ungroup()

  # includeSource
  includeSource <- "source_concept_id" %in% colnames(x)

  if (includeSource) {
    estimateForm <- "Standard: %s (%s); Source: %s (%s); %i (%.1f%%)"
    if (type == "gt") {
      estimateForm <- stringr::str_replace_all(estimateForm, ";", " <br>")
    }
    x <- x |>
      dplyr::mutate(estimate_value = sprintf(
        .env$estimateForm, .data$variable_name, .data$concept_id,
        .data$source_concept_name, .data$source_concept_id, .data$count,
        .data$percentage
      ))
  } else {
    estimateForm <- "%s (%s); %i (%.1f%%)"
    if (type == "gt") {
      estimateForm <- stringr::str_replace_all(estimateForm, ";", " <br>")
    }
    x <- x |>
      dplyr::mutate(estimate_value = sprintf(
        .env$estimateForm, .data$variable_name, .data$concept_id, .data$count,
        .data$percentage
      ))
  }

  x <- x |>
    dplyr::select(!dplyr::any_of(c(
      "variable_name", "concept_id", "source_concept_name", "source_concept_id",
      "count", "percentage"
    ))) |>
    dplyr::rename(window = "variable_level") |>
    dplyr::mutate(estimate_name = "counts", estimate_type = "character")
  header <- x |>
    dplyr::select(!dplyr::starts_with(c("estimate", "top"))) |>
    as.list() |>
    purrr::map(unique) |>
    purrr::keep(\(x) length(x) > 1) |>
    names()
  hide <- colnames(x)[!colnames(x) %in% c("top", "estimate_value", header)]

  # final table
  tab <- x |>
    visOmopResults::visTable(header = header, type = type, hide = hide, style = style)

  if (type == "gt") {
    tab <- gt::fmt_markdown(tab)
  }

  return(tab)
}

#' Explore and compare the large scale characteristics of cohorts
#'
#' @inheritParams resultDoc
#' @param compareBy A column to compare by it can be a choice between
#' "cdm_name", "cohort_name", strata columns, "variable_level" (window) and
#' "type". It can be left NULL for no comparison.
#' @param hide Columns to hide.
#' @param smdReference Level of reference for the Standardised Mean Differences
#' (SMD), it has to be one of the values of `compareBy` column. If NULL no SMDs
#' are displayed.
#' @param type Type of table to generate, it can be either `DT` or `reactable`.
#'
#' @return A visual table.
#' @export
#'
#' @examples
#' \dontrun{
#' library(CohortCharacteristics)
#' library(omock)
#' library(CDMConnector)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#'
#' cdm <- generateConceptCohortSet(
#'   cdm = cdm,
#'   conceptSet = list(viral_pharyngitis = 4112343),
#'   name = "my_cohort"
#' )
#'
#' result <- summariseLargeScaleCharacteristics(
#'   cohort = cdm$my_cohort,
#'   window = list(c(-Inf, -1), c(0, 0), c(1, Inf)),
#'   episodeInWindow = "drug_exposure"
#' )
#'
#' tableLargeScaleCharacteristics(result)
#'
#' tableLargeScaleCharacteristics(result,
#'                                compareBy = "variable_level")
#'
#' tableLargeScaleCharacteristics(result,
#'                                compareBy = "variable_level",
#'                                smdReference = "-inf to -1")
#'
#' cdmDisconnect(cdm)
#' }
#'
tableLargeScaleCharacteristics <- function(result,
                                           compareBy = NULL,
                                           hide = c("type"),
                                           smdReference = NULL,
                                           type = "reactable") {
  # initial checks
  result <- result |>
    omopgenerics::validateResultArgument() |>
    omopgenerics::filterSettings(.data$result_type == "summarise_large_scale_characteristics") |>
    dplyr::filter(.data$estimate_name == "percentage")

  strataCols <- omopgenerics::strataColumns(result)
  choic <- c("cdm_name", "cohort_name", strataCols, "variable_level", "type")
  hide <- hide %||% character()

  omopgenerics::assertChoice(type, choices = c("DT", "reactable"))
  omopgenerics::assertChoice(compareBy, choices = choic, length = 1, null = TRUE)
  omopgenerics::assertChoice(hide, choices = choic)

  rlang::check_installed(pkg = type)

  hide <- hide[!hide %in% compareBy]
  result <- omopgenerics::tidy(result) |>
    dplyr::select(!dplyr::all_of(hide))

  if (length(compareBy) == 0) {
    opts <- "percentage"
    smdReference <- NULL
  } else {
    opts <- unique(result[[compareBy]])
    omopgenerics::assertChoice(smdReference, choices = opts, length = 1, null = TRUE)
  }

  # pivot
  if (!is.null(compareBy)) {
    result <- result |>
      tidyr::pivot_wider(
        names_from = dplyr::all_of(compareBy),
        values_fill = 0,
        values_from = "percentage"
      )
  }

  result <- result |>
    dplyr::select(dplyr::any_of(c(
      "cdm_name", "cohort_name", strataCols, "type",
      "window" = "variable_level", "concept_name" = "variable_name",
      "concept_id", "source_concept_name", "source_concept_id", opts
    )))

  if (length(smdReference) > 0) {
    cols <- character()
    for (col in opts) {
      if (col == smdReference) {
        ref <- rlang::set_names(smdReference, paste0(smdReference, " (ref)"))
      } else {
        result <- result |>
          dplyr::mutate(!!paste0(col, " SMD") := qSmd(.data[[smdReference]], .data[[col]]))
        cols <- c(cols, col, paste0(col, " SMD"))
      }
    }
    result <- result |>
      dplyr::relocate(dplyr::all_of(c(ref, cols)), .after = dplyr::last_col())
  }

  if (type == "DT") {
    out <- DT::datatable(result)
  } else {
    out <- reactable::reactable(result)
  }

  return(out)
}
qSmd <- function(ref, comp) {
  dplyr::case_when(
    ref == 0 & comp == 0 ~ 0,
    ref == 100 & comp == 100 ~ 0,
    .default = round(suppressWarnings((comp - ref)/sqrt((comp * (100 - comp) + ref * (100 - ref)) / 2)), 4)
  )
}
validateType <- function(type) {
  if (is.null(type)) {
    type <- getOption(x = paste0("visOmopResults.tableType"), default = "gt")
  }
  omopgenerics::assertChoice(type, choices = visOmopResults::tableType(), length = 1)
  return(type)
}
