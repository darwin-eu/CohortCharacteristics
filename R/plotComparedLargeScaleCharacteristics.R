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

#' create a ggplot from the output of summariseLargeScaleCharacteristics.
#'
#' `r lifecycle::badge("experimental")`
#'
#' @inheritParams resultDoc
#' @param reference A named character to set up the reference.
#' @param missings Value to replace the missing value with. If NULL missing
#' values will be eliminated.
#' @inheritParams plotDoc
#'
#' @return A ggplot.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(CohortCharacteristics)
#' library(duckdb)
#' library(CDMConnector)
#' library(DrugUtilisation)
#' library(plotly, warn.conflicts = FALSE)
#'
#' con <- dbConnect(duckdb(), eunomiaDir())
#' cdm <- cdmFromCon(con, cdmSchem = "main", writeSchema = "main")
#'
#' cdm <- generateIngredientCohortSet(
#'   cdm = cdm, name = "my_cohort", ingredient = "acetaminophen"
#' )
#'
#' resultsLsc <- cdm$my_cohort |>
#'   summariseLargeScaleCharacteristics(
#'     window = list(c(-365, -1), c(1, 365)),
#'     eventInWindow = "condition_occurrence"
#'   )
#'
#' resultsLsc |>
#'   plotComparedLargeScaleCharacteristics(
#'     reference = c(variable_level = "-365 to -1"),
#'     colour = "variable_name",
#'     missings = NULL
#'   ) |>
#'   ggplotly()
#'
#' cdmDisconnect(cdm)
#' }
#'
plotComparedLargeScaleCharacteristics <- function(result,
                                                  reference,
                                                  missings = 0,
                                                  facet = NULL,
                                                  colour = NULL) {
  # validate result
  result <- omopgenerics::validateResultArgument(result)
  omopgenerics::assertNumeric(missings, min = 0, max = 100, length = 1, null = TRUE)
  omopgenerics::assertCharacter(reference, named = TRUE)

  # check settings
  result <- result |>
    visOmopResults::filterSettings(
      .data$result_type == "summarise_large_scale_characteristics"
    )

  if (nrow(result) == 0) {
    cli::cli_warn("`result` object does not contain any `result_type == 'summarise_large_scale_characteristics'` information.")
    return(emptyPlot())
  }

  checkVersion(result)

  checkReference(reference, result)

  labs <- unique(result$variable_level)

  result <- result |>
    dplyr::filter(.data$estimate_name == "percentage") |>
    tidy() |>
    dplyr::mutate(variable_level = factor(.data$variable_level, labs))

  cols <- colnames(result)
  cols <- cols[cols != "percentage"]
  result <- filterRef(result, reference) |>
    dplyr::select("concept_id", "percentage_reference" = "percentage") |>
    dplyr::full_join(
      filterRef(result, reference, TRUE) |>
        dplyr::rename("percentage_comparator" = "percentage"),
      by = "concept_id"
    ) |>
    correctMissings(missings)

  visOmopResults::scatterPlot(
    result = result,
    x = "percentage_reference",
    y = "percentage_comparator",
    point = TRUE,
    line = FALSE,
    ribbon = FALSE,
    facet = facet,
    colour = colour,
    group = "variable_name"
  )
}

checkReference <- function(reference, result, call = parent.frame()) {
  opts <- list(
    cdm_name = unique(result$cdm_name),
    variable_level = unique(result$variable_level)
  )
  opts <- c(opts, getValues(result, "group"), getValues(result, "strata"))
  comp <- names(opts)[lengths(opts) > 1]
  notPresent <- comp[!comp %in% names(reference)]
  if (length(notPresent) > 0) {
    c(
      "x" = "The following variables need to be present on reference: {.var {notPresent}}.",
      "i" = "Example: {.code reference = c({exampleRef(opts)})}."
    ) |>
      cli::cli_abort(call = call)
  }
  for (k in seq_along(reference)) {
    ref <- reference[k]
    variable <- names(ref)
    if (!ref %in% opts[[variable]]) {
      "wrong reference supplied for: {variable}; '{ref}' is not part of possible choices: {opts[[variable]]}." |>
        cli::cli_abort(call = call)
    }
  }
  invisible(reference)
}
getValues <- function(result, prefix) {
  result |>
    dplyr::select(dplyr::all_of(paste0(prefix, c("_name", "_level")))) |>
    dplyr::distinct() |>
    visOmopResults::splitAll() |>
    purrr::map(unique)
}
exampleRef <- function(opts) {
  purrr::imap_chr(opts, ~ paste0(.y, " = '", .x[1], "'")) |>
    paste0(collapse = ", ")
}
filterRef <- function(result, reference, negate = FALSE) {
  for (k in seq_along(reference)) {
    nm <- names(reference)[k]
    val <- reference[k] |> unname()
    id <- result[[nm]] == val
    if (negate) id <- !id
    if (k == 1) {
      idx <- id
    } else if (negate) {
      idx <- idx | id
    } else {
      idx <- idx & id
    }
  }
  result <- result |>
    dplyr::filter(.env$idx)
  return(result)
}
correctMissings <- function(result, missings) {
  if (is.null(missings)) {
    result <- result |>
      dplyr::filter(
        !is.na(.data$percentage_reference),
        !is.na(.data$percentage_comparator)
      )
  } else {
    result <- result |>
      dplyr::mutate(dplyr::across(
        c("percentage_reference", "percentage_comparator"),
        ~ dplyr::if_else(is.na(.x), missings, .x)
      ))
  }
  return(result)
}
