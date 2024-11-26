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

#' Plot the result of summariseCohortOverlap.
#'
#' `r lifecycle::badge("experimental")`
#'
#' @inheritParams resultDoc
#' @inheritParams uniqueCombinationsDoc
#' @param y Variables to use in y axis, if NULL all variables not present in
#' facet are used.
#' @inheritParams plotDoc
#' @param .options deprecated.
#'
#' @return A ggplot.
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#'
#' cdm <- mockCohortCharacteristics()
#'
#' overlap <- summariseCohortOverlap(cdm$cohort2)
#'
#' plotCohortOverlap(overlap, uniqueCombinations = FALSE)
#'
#' mockDisconnect(cdm)
#' }
#'
plotCohortOverlap <- function(result,
                              uniqueCombinations = TRUE,
                              y = NULL,
                              facet = c("cdm_name", "cohort_name_reference"),
                              colour = "variable_name",
                              .options = lifecycle::deprecated()) {
  plotInternal(
    result = result,
    resultType = "summarise_cohort_overlap",
    plotType = "barplot",
    facet = facet,
    colour = colour,
    uniqueCombinations = uniqueCombinations,
    y = "percentage",
    oneVariable = FALSE,
    toYears = FALSE
  ) +
    ggplot2::coord_flip() +
    ggplot2::theme(
      legend.position = "top",
      legend.title = ggplot2::element_blank()
    )
}
