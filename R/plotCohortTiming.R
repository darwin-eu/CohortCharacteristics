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
#' @inheritParams resultDoc
#' @param plotType Type of desired formatted table, possibilities are "boxplot" and
#' "densityplot".
#' @inheritParams timeScaleDoc
#' @inheritParams uniqueCombinationsDoc
#' @inheritParams plotDoc
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
#'   uniqueCombinations = FALSE,
#'   facet = c("cdm_name", "cohort_name_reference"),
#'   colour = c("cohort_name_comparator")
#' )
#'
#' plotCohortTiming(
#'   timings,
#'   plotType = "densityplot",
#'   timeScale = "years",
#'   uniqueCombinations = FALSE,
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
  # specific checks
  omopgenerics::assertChoice(plotType, c("boxplot", "densityplot"), length = 1)
  omopgenerics::assertChoice(timeScale, c("days", "years"), length = 1)
  result <- omopgenerics::validateResultArgument(result)

  # pre process
  result <- result |>
    dplyr::filter(.data$variable_name == "days_between_cohort_entries")

  # internal functions
  p <- plotInternal(
    result = result,
    resultType = "summarise_cohort_timing",
    plotType = plotType,
    facet = facet,
    colour = colour,
    uniqueCombinations = uniqueCombinations,
    oneVariable = TRUE,
    toYears = timeScale == "years",
    excludeGroup = "variable_level"
  )

  lab <- switch(timeScale,
                "days" = "Days between cohort entries",
                "years" = "Years between cohort entries")

  if (plotType == "boxplot") {
    p <- p +
      ggplot2::coord_flip() +
      ggplot2::geom_hline(
        yintercept = 0, colour = "black", linetype = "longdash", alpha = 0.5
      ) +
      ggplot2::labs(
        title = ggplot2::element_blank(),
        y = lab,
        x = ggplot2::element_blank()
      )
  } else if (plotType == "densityplot") {
    p <- p +
      ggplot2::geom_vline(
        xintercept = 0, colour = "black", linetype = "longdash", alpha = 0.5
      ) +
      ggplot2::labs(
        title = ggplot2::element_blank(),
        x = lab,
        y = ggplot2::element_blank()
      )
    p <- minimumRange(p, timeScale)
  }

  return(p)
}
minimumRange <- function(p, timeScale) {
  unit <- switch(timeScale, "days" = 1, "years" = 365)
  scale <- ggplot2::ggplot_build(p)$layout$panel_params[[1]]$x.range
  if (scale[2] - scale[1] < 5/unit) {
    scale <- round(mean(scale)*unit)/unit
    lims <- scale + 5/unit/2*c(-1, 1)
    p <- p +
      ggplot2::coord_cartesian(xlim = lims)
  }
  return(p)
}
