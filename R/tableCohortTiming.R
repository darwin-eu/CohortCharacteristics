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

#' Format a summariseCohortTiming result into a visual table.
#'
#' `r lifecycle::badge("experimental")`
#'
#' @inheritParams resultDoc
#' @inheritParams timeScaleDoc
#' @inheritParams uniqueCombinationsDoc
#' @inheritParams tableDoc
#'
#' @return A formatted table.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(CohortCharacteristics)
#' library(omock)
#' library(DrugUtilisation)
#'
#' cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#'
#' cdm <- generateIngredientCohortSet(
#'   cdm = cdm,
#'   name = "my_cohort",
#'   ingredient = c("acetaminophen", "morphine", "warfarin")
#' )
#'
#' timings <- summariseCohortTiming(cdm$my_cohort)
#'
#' tableCohortTiming(timings, timeScale = "years")
#'
#' cdmDisconnect(cdm)
#' }
#'
tableCohortTiming <- function(result,
                              timeScale = "days",
                              uniqueCombinations = TRUE,
                              type = NULL,
                              header = strataColumns(result),
                              groupColumn = c("cdm_name"),
                              hide = c("variable_level", settingsColumns(result)),
                              style = NULL,
                              .options = list()) {
  omopgenerics::assertChoice(timeScale, c("days", "years"), length = 1)
  omopgenerics::assertLogical(uniqueCombinations, length = 1)
  result |>
    tableCohortCharacteristics(
      resultType = "summarise_cohort_timing",
      header = header,
      groupColumn = groupColumn,
      hide = hide,
      rename = c("CDM name" = "cdm_name"),
      modifyResults = \(x, ...) {
        x <- x |>
          dplyr::filter(!.data$estimate_name %in% c("density_x", "density_y"))
        if (timeScale == "years") {
          x <- changeDaysToYears(x)
        }
        if (uniqueCombinations) {
          x <- getUniqueCombinationsSr(x)
        }
        return(x)
      },
      estimateName = c(
        "N" = "<count>",
        "Mean (SD)" = "<mean> (<sd>)",
        "Median [Q25 - Q75]" = "<median> [<q25> - <q75>]",
        "Range" = "<min> to <max>"
      ),
      type = type,
      style = style,
      .options = .options
    )
}
