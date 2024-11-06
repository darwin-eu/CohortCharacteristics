# Copyright 2022 DARWIN EU (C)
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
#' @param result A summariseCharacteristics result.
#' @param plotStyle Either `barplot`, `scatterplot` or `boxplot`. If `barplot`
#' or `scatterplot` subset to just one estimate.
#' @param facet Columns to facet by. See options with `tidyColumns(result)`.
#' Formula is also allowed to specify rows and columns.
#' @param colour Columns to color by. See options with `tidyColumns(result)`.
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
#'     plotStyle = "barplot",
#'     colour = "variable_level",
#'     facet = c("cdm_name", "cohort_name")
#'   )
#'
#' results |>
#'   filter(variable_name == "Age", estimate_name == "mean") |>
#'   plotCharacteristics(
#'     plotStyle = "scatterplot",
#'     facet = "cdm_name"
#'   )
#'
#' results |>
#'   filter(variable_name == "Age") |>
#'   plotCharacteristics(
#'     plotStyle = "boxplot",
#'     facet = "cdm_name",
#'     colour = "cohort_name"
#'   )
#'
#' mockDisconnect(cdm)
#' }
plotCharacteristics <- function(result,
                                plotStyle = "barplot",
                                facet = NULL,
                                colour = NULL) {
  result <- omopgenerics::validateResultArgument(result)
  omopgenerics::assertChoice(
    plotStyle, c("barplot", "scatterplot", "boxplot"),
    length = 1
  )

  result <- result |>
    visOmopResults::filterSettings(
      .data$result_type == "summarise_characteristics"
    )
  if (nrow(result) == 0) {
    cli::cli_warn("No summarised characteristics results found")
    return(emptyPlot())
  }

  variable <- oneVariable(result)

  if (plotStyle == "boxplot") {
    p <- visOmopResults::boxPlot(result, facet = facet, colour = colour) +
      ggplot2::labs(y = glue::glue("{variable}"))
  } else {
    estimate <- unique(result$estimate_name)
    if (length(estimate) > 1) {
      return(emptyPlot(
        "Only one estimate name can be plotted at a time.",
        "Please filter estimate_name column in results before passing to plotCharacteristics()"
      ))
    }
    x <- c(
      "variable_level", "cdm_name", visOmopResults::groupColumns(result),
      visOmopResults::strataColumns(result),
      visOmopResults::additionalColumns(result)
    )
    res <- result |>
      dplyr::select(
        "variable_level", "cdm_name", "group_name", "group_level",
        "strata_name", "strata_level", "additional_name", "additional_level"
      ) |>
      dplyr::distinct() |>
      visOmopResults::splitAll()
    x <- x[!x %in% facet]
    x <- x[purrr::map_lgl(x, \(x) res[[x]] |>
      unique() |>
      length() > 1)]
    if (plotStyle == "barplot") {
      p <- result |>
        visOmopResults::barPlot(
          x = x, y = estimate, facet = facet, colour = colour
        )
    } else if (plotStyle == "scatterplot") {
      p <- result |>
        visOmopResults::scatterPlot(
          x = x, y = estimate, facet = facet, colour = colour, line = FALSE,
          point = TRUE, ribbon = FALSE, group = colour
        )
    }
    p <- p +
      ggplot2::labs(y = glue::glue("{variable} ({estimate})"))
  }

  p <- p +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "top")

  return(p)
}
