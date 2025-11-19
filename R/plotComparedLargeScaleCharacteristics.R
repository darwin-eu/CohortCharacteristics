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
#' @inheritParams plotDoc
#' @param colour Columns to color by. See options with
#' `availablePlotColumns(result)`.
#' @param reference A named character to set up the reference. It must be one of
#' the levels of reference.
#' @param facet Columns to facet by. See options with
#' `availablePlotColumns(result)`. Formula is also allowed to specify rows and
#' columns.
#' @param missings Value to replace the missing value with. If NULL missing
#' values will be eliminated.
#'
#' @return A ggplot.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(CohortCharacteristics)
#' library(DrugUtilisation)
#' library(plotly, warn.conflicts = FALSE)
#'
#' cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
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
#'     colour = "variable_level",
#'     reference = "-365 to -1",
#'     missings = NULL
#'   ) |>
#'   ggplotly()
#'
#' cdmDisconnect(cdm)
#' }
#'
plotComparedLargeScaleCharacteristics <- function(result,
                                                  colour,
                                                  reference = NULL,
                                                  facet = NULL,
                                                  missings = 0,
                                                  style = "default") {
  rlang::check_installed("visOmopResults")

  # initial checks
  result <- omopgenerics::validateResultArgument(result) |>
    omopgenerics::filterSettings(.data$result_type == "summarise_large_scale_characteristics") |>
    dplyr::filter(.data$estimate_name == "percentage")
  strataCols <- omopgenerics::strataColumns(result)
  omopgenerics::assertNumeric(missings, length = 1, null = TRUE)

  choic <- c("cdm_name", "cohort_name", strataCols, "variable_level", "type")
  omopgenerics::assertChoice(colour, choices = choic, length = 1)
  result <- omopgenerics::tidy(result) |>
    dplyr::rename(concept_name = "variable_name")
  opts <- unique(result[[colour]])

  if (length(opts) < 2) {
    cli::cli_inform(c(x = "No multiple values for {.var {colour}} to compare."))
    p <- ggplot2::ggplot() +
      ggplot2::annotate(
        geom = "text", x = 0.5, y = 0.5, size = 6, hjust = 0.5,
        label = paste0("No multiple values to compare for: ", colour),
      ) +
      ggplot2::theme_void() +
      ggplot2::xlim(0, 1) +
      ggplot2::ylim(0, 1)
  } else {
    if (is.null(reference)) {
      reference <- opts[1]
    }
    omopgenerics::assertChoice(reference, choices = opts, length = 1)

    # prepare reference
    ref <- result |>
      dplyr::filter(.data[[colour]] == .env$reference) |>
      dplyr::rename(reference_percentage = "percentage") |>
      dplyr::select(!dplyr::all_of(colour)) |>
      dplyr::cross_join(dplyr::tibble(!!colour := opts[opts != reference]))
    join <- colnames(ref)[colnames(ref) != "reference_percentage"]
    result <- result |>
      dplyr::filter(.data[[colour]] != .env$reference) |>
      dplyr::full_join(ref, by = join) |>
      correctMissings(missings)

    label <- c(choic[choic != colour], "concept_name", "concept_id")
    colourLab <- paste0(
      "Comparator (",
      colour |>
        stringr::str_replace_all(pattern = "_", replacement = " ") |>
        stringr::str_to_sentence(),
      ")"
    )

    p <- visOmopResults::scatterPlot(
      result = result, x= "reference_percentage", y = "percentage",
      point = TRUE, line = FALSE, ribbon = FALSE, ymin = NULL, ymax = NULL,
      facet = facet, colour = colour, group = NULL, label = label, style = style
    ) +
      ggplot2::geom_line(
        mapping = ggplot2::aes(x = .data$x, y = .data$y),
        data = dplyr::tibble(x = c(0, 100), y = c(0, 100)),
        color = "black",
        linetype = "dashed",
        inherit.aes = FALSE
      ) +
      ggplot2::ylab("Comparator (%)") +
      ggplot2::xlab("Reference (%)") +
      ggplot2::labs(colour = colourLab, fill = colourLab)
  }

  return(p)
}

correctMissings <- function(result, missings) {
  if (is.null(missings)) {
    result <- result |>
      dplyr::filter(
        !is.na(.data$percentage),
        !is.na(.data$reference_percentage)
      )
  } else {
    result <- result |>
      dplyr::mutate(dplyr::across(
        c("reference_percentage", "percentage"),
        \(x) dplyr::if_else(is.na(x), missings, x)
      ))
  }
  return(result)
}
