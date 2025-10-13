# Copyright 2024 DARWIN EU (C)
#
# This file is part of CohortCharacteristics
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' Plot the result of summariseCohortCount.
#'
#' `r lifecycle::badge("experimental")`
#'
#' @inheritParams resultDoc
#' @param x Variables to use in x axis.
#' @inheritParams plotDoc
#'
#' @return A ggplot.
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(PatientProfiles)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' cdm <- mockCohortCharacteristics(numberIndividuals = 100)
#'
#' counts <- cdm$cohort2 |>
#'   addSex() |>
#'   addAge(ageGroup = list(c(0, 29), c(30, 59), c(60, Inf))) |>
#'   summariseCohortCount(strata = list("age_group", "sex", c("age_group", "sex"))) |>
#'   filter(variable_name == "Number subjects")
#'
#' counts |>
#'   plotCohortCount(
#'     x = "sex",
#'     facet = cohort_name ~ age_group,
#'     colour = "sex"
#'   )
#'
#' }
#'
plotCohortCount <- function(result,
                            x = NULL,
                            facet = c("cdm_name"),
                            colour = NULL) {
  p <- plotInternal(
    result = result,
    resultType = "summarise_cohort_count",
    plotType = "barplot",
    facet = facet,
    colour = colour,
    uniqueCombinations = FALSE,
    y = "count",
    x = x,
    oneVariable = TRUE,
    toYears = FALSE
  )

  if (is.null(x)) {
    p <- p +
      ggplot2::xlab("")
  }

  lab <- unique(result$variable_name)
  p <- p +
    ggplot2::ylab(lab)

  return(p)
}
