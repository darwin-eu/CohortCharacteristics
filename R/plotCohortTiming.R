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

#' Plot summariseCohortTiming results.
#'
#' `r lifecycle::badge("experimental")`
#'
#' @param result A summarised_result object. Output of summariseCohortTiming().
#' @param plotType Type of desired formatted table, possibilities are "boxplot" and
#' "density".
#' @param timeScale Time scale to plot results. Can be days or years.
#' @param uniqueCombinations Whether to restrict to unique reference and
#' comparator comparisons.
#' @param facet Columns to facet by. See options with `tidyColumns(result)`.
#' Formula is also allowed to specify rows and columns.
#' @param colour Columns to color by. See options with `tidyColumns(result)`.
#'
#' @return A ggplot.
#' @export
#'
#' @examples
#' \dontrun{
#' library(CohortCharacteristics)
#' library(duckdb)
#' library(CDMConnector)
#' library(DrugUtilisation)
#'
#' con <- dbConnect(duckdb(), eunomiaDir())
#' cdm <- cdmFromCon(con, cdmSchem = "main", writeSchema = "main")
#'
#' cdm <- generateIngredientCohortSet(
#'   cdm = cdm,
#'   name = "my_cohort",
#'   ingredient = c("acetaminophen", "morphine", "warfarin")
#' )
#'
#' timings <- summariseCohortTiming(cdm$my_cohort)
#'
#' plotCohortTiming(
#'   timings,
#'   timeScale = "years",
#'   facet = c("cdm_name", "cohort_name_reference"),
#'   colour = c("cohort_name_comparator")
#' )
#'
#' cdmDisconnect(cdm)
#' }
#'
plotCohortTiming <- function(result,
                             plotType = "boxplot",
                             timeScale = "days",
                             uniqueCombinations = TRUE,
                             facet = c("cdm_name", "cohort_name_reference"),
                             colour = c("cohort_name_comparator")) {
  result <- omopgenerics::validateResultArgument(result) |>
    visOmopResults::filterSettings(
      .data$result_type == "summarise_cohort_timing"
    )

  if (nrow(result) == 0) {
    cli::cli_warn("Empty result object")
    return(emptyPlot())
  }

  # initial checks
  omopgenerics::assertChoice(plotType, c("boxplot", "density"))
  omopgenerics::assertChoice(timeScale, c("days", "years"))
  omopgenerics::assertLogical(uniqueCombinations)

  if (plotType == "boxplot") {
    result <- result |>
      dplyr::filter(
        .data$variable_name == "days_between_cohort_entries",
        !.data$estimate_name %in% c("density_x", "density_y")
      )
    if (timeScale == "years") {
      result <- changeDaysToYears(result)
    }
  } else if (plotType == "density") {
    result <- result |>
      dplyr::filter(
        .data$variable_name == "days_between_cohort_entries",
        .data$estimate_name %in% c("density_x", "density_y")
      )
    if (timeScale == "years") {
      result <- result |>
        changeDaysToYears("density_x", 1 / 365.25) |>
        changeDaysToYears("density_y", 365.25)
    }
  }

  xLab <- switch(timeScale,
    "days" = "Days between cohort entries",
    "years" = "Years between cohort entries",
  )

  if (nrow(result) == 0) {
    cli::cli_warn("No timing results found")
    return(emptyPlot())
  }

  if (uniqueCombinations) result <- getUniqueCombinationsSr(result)

  if (plotType == "boxplot") {
    p <- visOmopResults::boxPlot(result, facet = facet, colour = colour) +
      ggplot2::coord_flip() +
      ggplot2::theme_bw() +
      ggplot2::labs(
        title = ggplot2::element_blank(),
        x = ggplot2::element_blank(),
        y = xLab
      )
  } else if (plotType == "density") {
    # plot scatter needs to allow x to be an estimate
    p <- result |>
      visOmopResults::scatterPlot(
        x = "density_x", y = "density_y", ymin = NULL, ymax = NULL, line = TRUE, point = FALSE,
        ribbon = FALSE, facet = facet, colour = colour, group = colour
      ) +
      ggplot2::theme_bw() +
      ggplot2::labs(
        title = ggplot2::element_blank(),
        x = xLab,
        y = ggplot2::element_blank()
      )
    unit <- switch(timeScale, "days" = 1, "years" = 365)
    scale <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x.range
    if (scale[2] - scale[1] < 5/unit) {
      scale <- round(mean(scale)*unit)/unit
      lims <- scale + 5/unit/2*c(-1, 1)
      p <- p +
        ggplot2::coord_cartesian(xlim = lims)
    }
  }

  p <- addLine(p)

  return(p)
}

addLine <- function(p) {
  p +
    ggplot2::geom_vline(
      xintercept = 0, colour = "black", linetype = "longdash", alpha = 0.5
    )
}
