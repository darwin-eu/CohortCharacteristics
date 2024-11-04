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

getUniqueCombinationsSr <- function(x) {
  xUniques <- x |>
    dplyr::select("group_name", "group_level") |>
    dplyr::distinct() |>
    visOmopResults::splitGroup() |>
    dplyr::mutate(id = dplyr::row_number())
  pairs <- xUniques |>
    dplyr::left_join(
      xUniques |>
        dplyr::rename(
          "cohort_name_reference" = "cohort_name_comparator",
          "cohort_name_comparator" = "cohort_name_reference"
        ),
      by = c("cohort_name_comparator", "cohort_name_reference"),
      suffix = c("_x", "_y")
    ) |>
    dplyr::filter(is.na(.data$id_y) | .data$id_x < .data$id_y) |>
    dplyr::select("cohort_name_comparator", "cohort_name_reference") |>
    visOmopResults::uniteGroup(
      cols = c("cohort_name_reference", "cohort_name_comparator")
    )
  x <- x |>
    dplyr::inner_join(pairs, by = c("group_name", "group_level"))
  return(x)
}
changeDaysToYears <- function(x, est = NULL, fact = 1 / 365.25) {
  oldVar <- "days_between_cohort_entries"
  newVar <- "years_between_cohort_entries"
  if (!is.null(est)) {
    id <- x$variable_name == oldVar & x$estimate_name %in% est
  } else {
    id <- x$variable_name == oldVar
  }
  x |>
    dplyr::mutate(
      estimate_value = dplyr::if_else(
        .env$id,
        as.character(suppressWarnings(as.numeric(.data$estimate_value)) * .env$fact),
        .data$estimate_value
      ),
      variable_name = dplyr::if_else(.env$id, .env$newVar, .data$variable_name),
      estimate_type = dplyr::if_else(.env$id, "numeric", .data$estimate_type)
    )
}
emptyPlot <- function(title = "No result to plot",
                      subtitle = "") {
  ggplot2::ggplot() +
    ggplot2::theme_void() +
    ggplot2::labs(
      title = title,
      subtitle = subtitle
    )
}
