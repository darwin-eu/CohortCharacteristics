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

#' Format a summarise_characteristics object into a visual table.
#'
#' `r lifecycle::badge("experimental")`
#'
#' @inheritParams resultDoc
#' @inheritParams tableDoc
#'
#' @return A formatted table.
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#'
#' cdm <- mockCohortCharacteristics()
#'
#' result <- summariseCharacteristics(cdm$cohort1)
#'
#' tableCharacteristics(result)
#'
#' }
#'
tableCharacteristics <- function(result,
                                 type = "gt",
                                 header = c("cdm_name", "cohort_name"),
                                 groupColumn = character(),
                                 hide = c(additionalColumns(result), settingsColumns(result)),
                                 style = "default",
                                 .options = list()) {
  result |> tableCohortCharacteristics(
      resultType = "summarise_characteristics",
      header = header,
      groupColumn = groupColumn,
      hide = hide,
      rename = c("CDM name" = "cdm_name"),
      modifyResults = \(x, ...) {
        x |>
          dplyr::filter(!.data$estimate_name %in% c("density_x", "density_y"))
      },
      estimateName = c(
        "N (%)" = "<count> (<percentage>%)",
        "N" = "<count>",
        "Median [Q25 - Q75]" = "<median> [<q25> - <q75>]",
        "Mean (SD)" = "<mean> (<sd>)",
        "Range" = "<min> to <max>"
      ),
      type = type,
      style = style,
      .options = .options
    )
}
