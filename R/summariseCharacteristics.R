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

#' Summarise characteristics of cohorts in a cohort table
#'
#' @inheritParams cohortDoc
#' @inheritParams cohortIdDoc
#' @inheritParams strataDoc
#' @param counts TRUE or FALSE. If TRUE, record and person counts will
#' be produced.
#' @param demographics TRUE or FALSE. If TRUE, patient demographics (cohort
#' start date, cohort end date, age, sex, prior observation, and future
#' observation will be summarised).
#' @param ageGroup A list of age groups to stratify results by.
#' @param tableIntersectFlag A list of arguments that uses
#' PatientProfiles::addTableIntersectFlag() to add variables to summarise.
#' @param tableIntersectCount A list of arguments that uses
#' PatientProfiles::addTableIntersectCount() to add variables to summarise.
#' @param tableIntersectDate A list of arguments that uses
#' PatientProfiles::addTableIntersectDate() to add variables to summarise.
#' @param tableIntersectDays A list of arguments that uses
#' PatientProfiles::addTableIntersectDays() to add variables to summarise.
#' @param cohortIntersectFlag A list of arguments that uses
#' PatientProfiles::addCohortIntersectFlag() to add variables to summarise.
#' @param cohortIntersectCount A list of arguments that uses
#' PatientProfiles::addCohortIntersectCount() to add variables to summarise.
#' @param cohortIntersectDate A list of arguments that uses
#' PatientProfiles::addCohortIntersectDate() to add variables to summarise.
#' @param cohortIntersectDays A list of arguments that uses
#' PatientProfiles::addCohortIntersectDays() to add variables to summarise.
#' @param conceptIntersectFlag A list of arguments that uses
#' PatientProfiles::addConceptIntersectFlag() to add variables to summarise.
#' @param conceptIntersectCount A list of arguments that uses
#' PatientProfiles::addConceptIntersectCount() to add variables to summarise.
#' @param conceptIntersectDate A list of arguments that uses
#' PatientProfiles::addConceptIntersectDate() to add variables to summarise.
#' @param conceptIntersectDays A list of arguments that uses
#' PatientProfiles::addConceptIntersectDays() to add variables to summarise.
#' @param otherVariables Other variables contained in cohort that you want to be
#' summarised.
#' @param estimates To modify the default estimates for a variable.
#' By default: 'min', 'q25', 'median', 'q75', 'max' for "date", "numeric" and
#' "integer" variables ("numeric" and "integer" also use 'mean' and 'sd'
#' estimates). 'count' and 'percentage' for "categorical" and "binary".
#' You have to provide them as a list: `list(age = c("median", "density"))`. You
#' can also use 'date', 'numeric', 'integer', 'binary', 'categorical',
#' 'demographics', 'intersect', 'other', 'table_intersect_count', ...
#' @param weights Column in cohort that points to weights of each individual.
#' @param otherVariablesEstimates deprecated.
#'
#' @return A summary of the characteristics of the cohorts in the cohort table.
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(dplyr, warn.conflicts = FALSE)
#' library(CohortCharacteristics)
#' library(PatientProfiles)
#'
#' cdm <- mockCohortCharacteristics()
#'
#' cdm$cohort1 |>
#'   addSex() |>
#'   addAge(
#'     ageGroup = list(c(0, 40), c(41, 150))
#'   ) |>
#'   summariseCharacteristics(
#'     strata = list("sex", "age_group"),
#'     cohortIntersectFlag = list(
#'       "Cohort 2 Flag" = list(
#'         targetCohortTable = "cohort2", window = c(-365, 0)
#'       )
#'     ),
#'     cohortIntersectCount = list(
#'       "Cohort 2 Count" = list(
#'         targetCohortTable = "cohort2", window = c(-365, 0)
#'       )
#'     )
#'   ) |>
#'   glimpse()
#'
#' }
summariseCharacteristics <- function(cohort,
                                     cohortId = NULL,
                                     strata = list(),
                                     counts = TRUE,
                                     demographics = TRUE,
                                     ageGroup = NULL,
                                     tableIntersectFlag = list(),
                                     tableIntersectCount = list(),
                                     tableIntersectDate = list(),
                                     tableIntersectDays = list(),
                                     cohortIntersectFlag = list(),
                                     cohortIntersectCount = list(),
                                     cohortIntersectDate = list(),
                                     cohortIntersectDays = list(),
                                     conceptIntersectFlag = list(),
                                     conceptIntersectCount = list(),
                                     conceptIntersectDate = list(),
                                     conceptIntersectDays = list(),
                                     otherVariables = character(),
                                     estimates = list(),
                                     weights = NULL,
                                     otherVariablesEstimates = lifecycle::deprecated()) {
  # check initial tables
  cdm <- omopgenerics::cdmReference(cohort)
  cohort <- omopgenerics::validateCohortArgument(cohort)
  cohortId <- omopgenerics::validateCohortIdArgument({{cohortId}}, cohort)
  omopgenerics::assertLogical(demographics, length = 1)
  cdm <- omopgenerics::validateCdmArgument(cdm)
  strata <- omopgenerics::validateStrataArgument(strata = strata, table = cohort)
  ageGroup <- omopgenerics::validateAgeGroupArgument(ageGroup)
  omopgenerics::assertLogical(counts)
  tableIntersectFlag <- assertIntersect(tableIntersectFlag)
  tableIntersectCount <- assertIntersect(tableIntersectCount)
  tableIntersectDate <- assertIntersect(tableIntersectDate)
  tableIntersectDays <- assertIntersect(tableIntersectDays)
  cohortIntersectFlag <- assertIntersect(cohortIntersectFlag)
  cohortIntersectCount <- assertIntersect(cohortIntersectCount)
  cohortIntersectDate <- assertIntersect(cohortIntersectDate)
  cohortIntersectDays <- assertIntersect(cohortIntersectDays)
  conceptIntersectFlag <- assertIntersect(conceptIntersectFlag)
  conceptIntersectCount <- assertIntersect(conceptIntersectCount)
  conceptIntersectDate <- assertIntersect(conceptIntersectDate)
  conceptIntersectDays <- assertIntersect(conceptIntersectDays)
  otherVariables <- checkOtherVariables(otherVariables, cohort)
  omopgenerics::assertList(estimates, named = TRUE, class = "character")
  if (!is.null(weights)) {
    weights <- omopgenerics::validateColumn(weights, x = cohort, type = "numeric")
  }

  if (lifecycle::is_present(otherVariablesEstimates)) {
    lifecycle::deprecate_stop(
      when = "0.4.0",
      what = "summariseCharacteristics(otherVariablesEstimates= )",
      with = "summariseCharacteristics(estimates= )",
      details = "See `estimates` argument documentation."
    )
  }

  srSet <- dplyr::tibble(
    result_id = 1L,
    package_name = "CohortCharacteristics",
    package_version = pkgVersion(),
    result_type = "summarise_characteristics",
    table_name = dplyr::coalesce(omopgenerics::tableName(cohort), "temp")
  )

  # return empty result if no analyses chosen
  if (length(strata) == 0 &&
    isFALSE(counts) &&
    isFALSE(demographics) &&
    is.null(ageGroup) &&
    length(tableIntersectFlag) == 0 &&
    length(tableIntersectCount) == 0 &&
    length(tableIntersectDate) == 0 &&
    length(tableIntersectDays) == 0 &&
    length(cohortIntersectFlag) == 0 &&
    length(cohortIntersectCount) == 0 &&
    length(cohortIntersectDate) == 0 &&
    length(cohortIntersectDays) == 0 &&
    length(conceptIntersectFlag) == 0 &&
    length(conceptIntersectCount) == 0 &&
    length(conceptIntersectDate) == 0 &&
    length(conceptIntersectDays) == 0 &&
    all(lengths(otherVariables) == 0)) {
    return(omopgenerics::emptySummarisedResult(settings = srSet))
  }

  # select necessary variables
  cohort <- cohort |>
    PatientProfiles::filterCohortId(cohortId = cohortId) |>
    dplyr::select(
      "cohort_definition_id", "subject_id", "cohort_start_date",
      "cohort_end_date", dplyr::all_of(unique(unlist(strata))),
      dplyr::all_of(otherVariables), dplyr::all_of(weights)
    )

  if (omopgenerics::isTableEmpty(cohort)) {
    cohortNames <- omopgenerics::settings(cohort)$cohort_name
    if (any(c("subject_id", "person_id") %in% colnames(cohort))) {
      variables <- c("Number subjects", "Number records")
    } else {
      variables <- "Number records"
    }
    result <- tidyr::expand_grid(
      "group_level" = cohortNames, "variable_name" = variables
    ) |>
      dplyr::mutate(
        "result_id" = as.integer(1),
        "cdm_name" = omopgenerics::cdmName(cdm),
        "group_name" = "cohort_name",
        "strata_name" = "overall",
        "strata_level" = "overall",
        "variable_level" = as.character(NA),
        "estimate_name" = "count",
        "estimate_type" = "integer",
        "estimate_value" = "0",
        "additional_name" = "overall",
        "additional_level" = "overall"
      ) |>
      omopgenerics::newSummarisedResult(settings = srSet)
    return(result)
  }

  dic <- dplyr::tibble(
    short_name = character(), new_variable_name = character(),
    new_variable_level = character(), table = character(), window = character(),
    value = character()
  )
  variables <- list()

  # demographics
  if (demographics | length(ageGroup) > 0) {
    cli::cli_alert_info("adding demographics columns")

    sex <- uniqueVariableName()
    age <- uniqueVariableName()
    priorObservation <- uniqueVariableName()
    futureObservation <- uniqueVariableName()
    duration <- uniqueVariableName()
    demographicsCategorical <- sex

    if (!is.null(ageGroup)) {
      # update names
      newNames <- uniqueVariableName(length(ageGroup))
      dic <- dic |>
        dplyr::union_all(dplyr::tibble(
          short_name = newNames,
          new_variable_name = names(ageGroup),
          new_variable_level = as.character(NA),
          table = as.character(NA),
          window = as.character(NA),
          value = as.character(NA)
        ))
      names(ageGroup) <- newNames
      variables <- variables |>
        updateVariables(list(categorical = newNames, demographics = newNames))
    }

    if (demographics) {
      dic <- dic |>
        dplyr::union_all(dplyr::tibble(
          short_name = c(sex, age, priorObservation, futureObservation, duration),
          new_variable_name = c(
            "sex", "age", "prior_observation", "future_observation",
            "days_in_cohort"
          ),
          new_variable_level = as.character(NA),
          table = as.character(NA),
          window = as.character(NA),
          value = as.character(NA)
        ))
      variables <- variables |>
        updateVariables(list(
          date = c("cohort_start_date", "cohort_end_date"),
          numeric = c(priorObservation, futureObservation, age, duration),
          categorical = sex,
          demographics = c(
            priorObservation, futureObservation, age, duration, sex,
            "cohort_start_date", "cohort_end_date"
          )
        ))
    }

    # add demographics
    cohort <- cohort |>
      PatientProfiles::addDemographics(
        ageGroup = ageGroup,
        missingAgeGroupValue = "Unknown",
        sex = demographics,
        sexName = sex,
        missingSexValue = "Unknown",
        age = demographics,
        ageName = age,
        priorObservation = demographics,
        priorObservationName = priorObservation,
        futureObservation = demographics,
        futureObservationName = futureObservation
      ) %>%
      dplyr::mutate(!!duration := as.integer(clock::date_count_between(
        start = .data$cohort_start_date,
        end = .data$cohort_end_date,
        precision = "day"
      )) + 1L)
  }

  # intersects
  intersects <- c(
    "tableIntersectFlag", "tableIntersectCount", "tableIntersectDate",
    "tableIntersectDays", "cohortIntersectFlag", "cohortIntersectCount",
    "cohortIntersectDate", "cohortIntersectDays", "conceptIntersectFlag",
    "conceptIntersectCount", "conceptIntersectDate", "conceptIntersectDays"
  )
  for (intersect in intersects) {
    values <- eval(parse(text = intersect))
    funName <- paste0(
      "PatientProfiles::add", toupper(substr(intersect, 1, 1)),
      substr(intersect, 2, nchar(intersect))
    )
    value <- getValue(intersect)
    type <- getType(intersect)

    for (k in seq_along(values)) {
      cli::cli_inform(c("i" = "adding {intersect} {k}/{length(values)}"))

      val <- values[[k]]

      if (type == "cohort") {
        # cohort variables
        cohortInterest <- val$targetCohortTable
        set <- settings(cdm[[cohortInterest]])
        shortNames <- uniqueVariableName(nrow(set))
        attr(cdm[[cohortInterest]], "cohort_set") <- set |>
          dplyr::select("cohort_definition_id") |>
          dplyr::mutate("cohort_name" = shortNames)
        val$nameStyle <- "{cohort_name}"
        attr(cohort, "cdm_reference") <- cdm
        # update dic
        addDic <- dplyr::tibble(
          "new_variable_level" = set$cohort_name,
          "table" = cohortInterest
        )
      } else if (type == "concept") {
        # concept variables
        shortNames <- uniqueVariableName(length(val$conceptSet))
        val$nameStyle <- "{concept_name}"
        # update dic
        addDic <- dplyr::tibble(
          "new_variable_level" = names(val$conceptSet),
          "table" = NA
        )
        names(val$conceptSet) <- shortNames
      } else if (type == "table") {
        # table variables
        shortNames <- uniqueVariableName()
        val$nameStyle <- shortNames
        # update dic
        addDic <- dplyr::tibble(
          "new_variable_level" = NA,
          "table" = val$tableName
        )
      }
      dic <- dic |>
        dplyr::union_all(
          addDic |>
            dplyr::mutate(
              "short_name" = shortNames,
              "new_variable_name" = names(values)[k],
              "window" = names(val$window),
              "value" = value
            )
        )

      vars <- list()
      vars$intersect <- shortNames
      vars[[omopgenerics::toSnakeCase(intersect)]] <- shortNames
      nm <- switch (value,
        "date" = "date",
        "days" = "numeric",
        "count" = "numeric",
        "flag" = "binary"
      )
      vars[[nm]] <- shortNames
      variables <- updateVariables(variables, vars)

      val$x <- cohort

      cohort <- do.call(eval(parse(text = funName)), val)

      if (type == "cohort") {
        attr(cdm[[cohortInterest]], "cohort_set") <- set
      }
    }
  }

  # other variables
  typesOtherVariables <- cohort |>
    dplyr::select(dplyr::all_of(otherVariables)) |>
    PatientProfiles::variableTypes()
  vars <- list()
  vars$date <- typesOtherVariables$variable_name[typesOtherVariables$variable_type == "date"]
  vars$numeric <- typesOtherVariables$variable_name[typesOtherVariables$variable_type == "numeric"]
  vars$integer <- typesOtherVariables$variable_name[typesOtherVariables$variable_type == "integer"]
  vars$categorical <- typesOtherVariables$variable_name[typesOtherVariables$variable_type == "categorical"]
  vars$binary <- typesOtherVariables$variable_name[typesOtherVariables$variable_type == "binary"]
  vars$other <- typesOtherVariables$variable_name
  variables <- updateVariables(variables, vars)

  # assign each variable each estimate
  varest <- variablesEstimates(variables, estimates, dic)

  cli::cli_alert_info("summarising data")
  #summarise results
  results <- purrr::map(cohortId, \(x) {

    cohortX <- cohort |>
      dplyr::filter(.data$cohort_definition_id == .env$x) |>
      dplyr::collect()

    cohortName <- omopgenerics::settings(cohort) |>
      dplyr::filter(.data$cohort_definition_id == .env$x) |>
      dplyr::pull("cohort_name")

    cli::cli_alert_info("summarising cohort {.pkg {cohortName}}")
    suppressMessages(
      cohortX |>
        PatientProfiles::summariseResult(
          group = list(),
          strata = strata,
          variables = varest$variables,
          estimates = varest$estimates,
          counts = counts,
          weights = weights
        ) |>
        dplyr::mutate(group_level = .env$cohortName, group_name = "cohort_name")
    )

  }) |>
    omopgenerics::bind() |>
    dplyr::mutate(cdm_name = omopgenerics::cdmName(cdm))

  # order result
  combinations <- getCombinations(
    dplyr::tibble(group_level = settings(cohort)$cohort_name),
    getStratas(cohort, strata),
    results |>
      dplyr::select("variable_name", "variable_level") |>
      dplyr::distinct() |>
      arrangeAgeGroup(ageGroup),
    results |>
      dplyr::select("estimate_name") |>
      dplyr::distinct()
  ) |>
    dplyr::mutate(order_id = dplyr::row_number())
  results <- results |>
    dplyr::left_join(
      combinations,
      by = c(
        "group_level", "strata_name", "strata_level", "variable_name",
        "variable_level", "estimate_name"
      )
    ) |>
    dplyr::arrange(.data$order_id) |>
    dplyr::select(-"order_id")

  # rename variables
  results <- results |>
    dplyr::left_join(
      dic |> dplyr::rename("variable_name" = "short_name"),
      by = "variable_name"
    ) |>
    dplyr::mutate(
      "variable_name" = dplyr::if_else(
        is.na(.data$new_variable_name),
        .data$variable_name,
        .data$new_variable_name
      ),
      "variable_level" = dplyr::if_else(
        is.na(.data$new_variable_level),
        .data$variable_level,
        .data$new_variable_level
      )
    ) |>
    dplyr::select(-c(
      "new_variable_name", "new_variable_level", "additional_name",
      "additional_level"
    )) |>
    dplyr::mutate(dplyr::across(
      c("variable_name", "variable_level"),
      ~ stringr::str_to_sentence(gsub("_", " ", .x))
    )) |>
    omopgenerics::uniteAdditional() |>
    dplyr::select(!c("table", "window", "value")) |>
    dplyr::mutate("result_id" = 1L) |>
    omopgenerics::newSummarisedResult(settings = srSet)

  cli::cli_alert_success("summariseCharacteristics finished!")

  return(results)
}

updateVariables <- function(variables,
                            args) {
  for (nm in names(args)) {
    variables[[nm]] <- c(variables[[nm]], args[[nm]])
  }
  return(variables)
}
binaryVariable <- function(x) {
  u <- unique(x)
  if (length(u) <= 3) {
    u <- as.character(u)
    return(all(u %in% c("0", "1", NA_character_)))
  }
  return(FALSE)
}
uniqueVariableName <- function(n = 1) {
  if (n != 0) {
    i <- getOption("unique_variable_name", 0) + 1:n
    options(unique_variable_name = i[length(i)])
    x <- sprintf("variable_%05i", i)
  } else {
    x <- NULL
  }
  return(x)
}
getValue <- function(name) {
  strsplit(name, "Intersect") |>
    unlist() |>
    dplyr::nth(2) |>
    tolower()
}
getType <- function(name) {
  strsplit(name, "Intersect") |>
    unlist() |>
    dplyr::first()
}
getSummaryName <- function(intersect) {
  paste0(
    c(
      "summarised",
      intersect |> snakecase::to_snake_case() |> strsplit("_") |> unlist()
    ),
    collapse = "_"
  )
}
arrangeAgeGroup <- function(x, ageGroup) {
  if (length(ageGroup) == 0) return(x)
  tib <- ageGroup |>
    purrr::imap(\(x, nm) {
      dplyr::tibble(variable_name = nm, variable_level = names(x))
    }) |>
    dplyr::bind_rows() |>
    dplyr::mutate(id = dplyr::row_number())
  variableId <- x |>
    dplyr::select("variable_name") |>
    dplyr::distinct() |>
    dplyr::mutate(variable_id = dplyr::row_number())
  x |>
    dplyr::inner_join(variableId, by = "variable_name") |>
    dplyr::full_join(tib, by = c("variable_name", "variable_level")) |>
    dplyr::mutate(id = dplyr::coalesce(.data$id, 0L)) |>
    dplyr::arrange(.data$variable_id, .data$id) |>
    dplyr::select("variable_name", "variable_level")
}
variablesEstimates <- function(variables, estimates, dic) {
  # warn ignored
  ignored <- names(estimates) |>
    purrr::keep(\(x) !x %in% c(names(variables), unlist(variables), dic$new_variable_name))
  if (length(ignored) > 0) {
    "{.var {ignored}} names in estimates ignored as not present in data." |>
      cli::cli_warn()
  }

  if (length(variables) == 0) {
    return(list(variables = list(), estimates = list()))
  }

  # get new variables
  newVariables <- variables |>
    unlist(use.names = FALSE) |>
    unique() |>
    rlang::set_names() |>
    as.list() |>
    purrr::map(\(x) {
      nms <- variables |>
        purrr::keep(\(xx) x %in% xx) |>
        purrr::compact() |>
        names()
      unique(c(x, nms, dic$new_variable_name[dic$short_name == x]))
    })

  # get new estimates
  newEstimates <- newVariables |>
    purrr::map(\(x) unique(unlist(purrr::map(x, \(xx) estimates[[xx]]))))

  # add default estimates if empty
  defaults <- list(
    date = c("min", "q25", "median", "q75", "max"),
    numeric = c("min", "q25", "median", "q75", "max", "mean", "sd"),
    integer = c("min", "q25", "median", "q75", "max", "mean", "sd"),
    categorical = c("count", "percentage"),
    binary = c("count", "percentage")
  )
  newEstimates <- newEstimates |>
    purrr::imap(\(x, nm) {
      if (is.null(x)) {
        type <- names(defaults)[names(defaults) %in% newVariables[[nm]]]
        x <- unique(unlist(defaults[type]))
      }
      x
    }) |>
    purrr::compact()

  newVariables <- names(newEstimates) |>
    rlang::set_names() |>
    as.list()

  nms <- names(newVariables)

  # return both lists
  list(variables = newVariables[nms], estimates = newEstimates[nms])
}
