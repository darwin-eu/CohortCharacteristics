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

#' @importFrom omopgenerics suppress
#' @export
omopgenerics::suppress

#' @importFrom omopgenerics settings
#' @export
omopgenerics::settings

#' @importFrom omopgenerics bind
#' @export
omopgenerics::bind

#' @importFrom omopgenerics importSummarisedResult
#' @export
omopgenerics::importSummarisedResult

#' @importFrom omopgenerics exportSummarisedResult
#' @export
omopgenerics::exportSummarisedResult

#' @importFrom omopgenerics tidy
#' @export
omopgenerics::tidy

#' @importFrom omopgenerics groupColumns
#' @export
omopgenerics::groupColumns

#' @importFrom omopgenerics strataColumns
#' @export
omopgenerics::strataColumns

#' @importFrom omopgenerics additionalColumns
#' @export
omopgenerics::additionalColumns

#' @importFrom omopgenerics settingsColumns
#' @export
omopgenerics::settingsColumns

#' It creates a mock database for testing CohortCharacteristics package
#'
#' @param con A DBI connection to create the cdm mock object.
#' @param writeSchema Name of an schema on the same connection with writing
#' permissions.
#' @param numberIndividuals Number of individuals to create in the cdm
#' reference.
#' @param ... User self defined tables to put in cdm, it can input as many
#' as the user want.
#' @param seed A number to set the seed. If NULL seed is not used.
#'
#' @return A mock cdm_reference object created following user's specifications.
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(CDMConnector)
#'
#' cdm <- mockCohortCharacteristics()
#'
#' mockDisconnect(cdm = cdm)
#' }
#'
mockCohortCharacteristics <- PatientProfiles::mockPatientProfiles

#' @importFrom PatientProfiles mockDisconnect
#' @export
PatientProfiles::mockDisconnect
