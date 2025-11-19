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
#' result <- summariseCohortCount(cdm$cohort1)
#'
#' tableCohortCount(result)
#'
#' }
#'
tableCohortCount <- function(result,
                             type = "gt",
                             header = "cohort_name",
                             groupColumn = character(),
                             hide = c("variable_level", settingsColumns(result)),
                             style = "default",
                             .options = list()) {
  result |>
    tableCohortCharacteristics(
      resultType = "summarise_cohort_count",
      header = header,
      groupColumn = groupColumn,
      hide = hide,
      rename = c("CDM name" = "cdm_name"),
      modifyResults = NULL,
      estimateName = c("N" = "<count>"),
      type = type,
      style = style,
      .options = .options
    )
}
