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
  if (lifecycle::is_present(.options)) {
    lifecycle::deprecate_warn(when = "0.3.0", what = "plotCohortOverlap(.options= )")
  }

  # check input
  result <- omopgenerics::validateResultArgument(result)
  omopgenerics::assertLogical(uniqueCombinations, length = 1)

  # resultType
  result <- result |>
    omopgenerics::filterSettings(.data$result_type == "summarise_cohort_overlap")
  if (nrow(result) == 0) {
    cli::cli_warn("No results found with `result_type == 'summarise_cohort_overlap'`")
    return(emptyPlot("No results found with `result_type == 'summarise_cohort_overlap'`"))
  }

  checkVersion(result)

  # uniqueCombinations
  if (uniqueCombinations) {
    result <- getUniqueCombinationsSr(result)
  }

  notUnique <- notUniqueColumns(result)
  x <- notUnique[!notUnique %in% c(colour, asCharacterFacet(facet))]
  if (length(x) == 0) {
    result <- omopgenerics::tidy(result)
    x <- omopgenerics::uniqueId(exclude = colnames(result))
    result <- dplyr::mutate(result, !!x := "")
  }
  group <- notUnique
  if (length(group) == 0) {
    group <- NULL
  }

  result <- result |>
    omopgenerics::tidy() |>
    dplyr::mutate(variable_name = factor(
      .data$variable_name,
      levels = c(
        "Only in reference cohort", "In both cohorts",
        "Only in comparator cohort"
      )
    ))

  visOmopResults::barPlot(
    result = result,
    x = x,
    y = "percentage",
    facet = facet,
    colour = colour,
    label = notUnique
  )  +
    ggplot2::geom_bar(stat = "identity") +
    ggplot2::theme_bw() +
    ggplot2::coord_flip() +
    ggplot2::theme(
      legend.position = "top",
      legend.title = ggplot2::element_blank()
    ) +
    ggplot2::geom_bar(stat = "identity")
}
