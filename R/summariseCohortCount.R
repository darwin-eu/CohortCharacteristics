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

#' Summarise counts for cohorts in a cohort table
#'
#' @inheritParams cohortDoc
#' @inheritParams cohortIdDoc
#' @inheritParams strataDoc
#'
#' @export
#'
#' @return  A summary of counts of the cohorts in the cohort table.
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' cdm <- mockCohortCharacteristics()
#'
#' summariseCohortCount(cohort = cdm$cohort1) |>
#'   glimpse()
#'
#' mockDisconnect(cdm)
#' }
summariseCohortCount <- function(cohort,
                                 cohortId = NULL,
                                 strata = list()) {
  res <- summariseCharacteristics(
    cohort,
    cohortId = cohortId,
    strata = strata,
    counts = TRUE,
    demographics = FALSE
  )
  omopgenerics::newSummarisedResult(
    res,
    settings = settings(res) |>
      dplyr::mutate(
        "result_type" = "summarise_cohort_count",
        "table_name" = dplyr::coalesce(omopgenerics::tableName(cohort), "temp")
      )
  )
}
