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

#' Create a ggplot from the output of summariseCharacteristics.
#'
#' `r lifecycle::badge('experimental')`
#'
#' @inheritParams resultDoc
#' @param plotType Either `barplot`, `scatterplot` or `boxplot`. If `barplot`
#' or `scatterplot` subset to just one estimate.
#' @inheritParams plotDoc
#' @param plotStyle deprecated.
#'
#' @return A ggplot.
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' cdm <- mockCohortCharacteristics()
#'
#' results <- summariseCharacteristics(
#'   cohort = cdm$cohort1,
#'   ageGroup = list(c(0, 19), c(20, 39), c(40, 59), c(60, 79), c(80, 150)),
#'   tableIntersectCount = list(
#'     tableName = "visit_occurrence", window = c(-365, -1)
#'   ),
#'   cohortIntersectFlag = list(
#'     targetCohortTable = "cohort2", window = c(-365, -1)
#'   )
#' )
#'
#' results |>
#'   filter(
#'     variable_name == "Cohort2 flag -365 to -1", estimate_name == "percentage"
#'   ) |>
#'   plotCharacteristics(
#'     plotType = "barplot",
#'     colour = "variable_level",
#'     facet = c("cdm_name", "cohort_name")
#'   )
#'
#' results |>
#'   filter(variable_name == "Age", estimate_name == "mean") |>
#'   plotCharacteristics(
#'     plotType = "scatterplot",
#'     facet = "cdm_name"
#'   )
#'
#' results |>
#'   filter(variable_name == "Age", group_level == "cohort_1") |>
#'   plotCharacteristics(
#'     plotType = "boxplot",
#'     facet = "cdm_name",
#'     colour = "cohort_name"
#'   )
#'
#' mockDisconnect(cdm)
#' }
plotCharacteristics <- function(result,
                                plotType = "barplot",
                                facet = NULL,
                                colour = NULL,
                                plotStyle = lifecycle::deprecated()) {
  # check input
  result <- omopgenerics::validateResultArgument(result)
  omopgenerics::assertChoice(
    plotType, choices = c("barplot", "scatterplot", "boxplot", "densityplot"), length = 1
  )

  # deprecation
  if (lifecycle::is_present(plotStyle)) {
    lifecycle::deprecate_soft(
      when = "0.4.0",
      what = "plotCharacteristics(plotStyle= )",
      with = "plotCharacteristics(plotType= )"
    )
    if (missing(plotType)) {
      plotType <- plotStyle
    }
  }

  lab <- unique(result$variable_name)
  x <- notUniqueColumns(result)
  x <- x[!x %in% asCharacterFacet(facet)]

  # check only one estimate
  if (!plotType %in% c("boxplot","densityplot")) {
    estimate <- unique(result$estimate_name)
    if (length(estimate) > 1) {
      return(emptyPlot(
        "Only one estimate name can be plotted at a time.",
        "Please filter estimate_name column in results before passing to plotCharacteristics()"
      ))
    }
    lab <- paste0(lab, " (", estimate, ")")
  } else {
    estimate <- NULL
  }

  if (!plotType == "densityplot") {
    # internal functions
    p <- plotInternal(
      result = result,
      resultType = "summarise_characteristics",
      plotType = plotType,
      facet = facet,
      colour = colour,
      uniqueCombinations = FALSE,
      x = x,
      y = estimate,
      oneVariable = TRUE,
      toYears = FALSE
    ) +
      ggplot2::ylab(lab)
  } else {
    # internal functions
    p <- plotInternal(
      result = result,
      resultType = "summarise_characteristics",
      plotType = plotType,
      facet = facet,
      colour = colour,
      uniqueCombinations = FALSE,
      oneVariable = TRUE,
      toYears = FALSE,
      excludeGroup = "variable_level"
    ) +
      ggplot2::labs(
        title = ggplot2::element_blank(),
        x = lab,
        y = ggplot2::element_blank()
      )

  }

  p <- p + ggplot2::theme(legend.position = "top")

  if (length(x) == 0) {
    p <- p +
      ggplot2::xlab(label = ggplot2::element_blank())
  }

  return(p)
}
