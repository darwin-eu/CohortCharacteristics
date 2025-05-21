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

#' @noRd
checkOtherVariables <- function(otherVariables, cohort, call = rlang::env_parent()) {
  omopgenerics::assertCharacter(otherVariables, call = call, unique = TRUE)
  if (!all(unlist(otherVariables) %in% colnames(cohort))) {
    cli::cli_abort("otherVariables must point to columns in cohort.", call = call)
  }
  return(invisible(otherVariables))
}

assertIntersect <- function(intersect) {
  name <- substitute(intersect)
  functionName <- paste0(
    "PatientProfiles::add", toupper(substr(name, 1, 1)),
    substr(name, 2, nchar(name))
  )
  arguments <- formals(eval(parse(text = functionName)))
  arguments <- arguments[!names(arguments) %in% c("x", "cdm")]

  if (any(c("targetCohortTable", "tableName", "conceptSet") %in% names(intersect))) {
    intersect <- list(intersect)
  }

  namesIntersect <- names(intersect)
  if (is.null(namesIntersect)) {
    namesIntersect <- rep("", length(intersect))
  }

  for (k in seq_along(intersect)) {
    # get variables
    nams <- names(intersect[[k]])

    # validate
    extraArguments <- names(intersect[[k]])
    extraArguments <- extraArguments[!extraArguments %in% names(arguments)]
    if (length(extraArguments) > 0) {
      cli::cli_abort(c(
        "{extraArguments} are not arguments of {functionName}()."
      ))
    }
    required <- character()
    for (kk in seq_along(arguments)) {
      x <- arguments[[kk]]
      if (missing(x)) {
        required <- c(required, names(arguments)[kk])
      }
    }
    notPresent <- required[!required %in% names(intersect[[k]])]
    if (length(notPresent) > 0) {
      cli::cli_abort(c(
        "{notPresent} need to be provided for {functionName}()."
      ))
    }
    if ("window" %in% nams) {
      if (!is.list(intersect[[k]]$window)) {
        intersect[[k]]$window <- list(intersect[[k]]$window)
      }
      if (length(intersect[[k]]$window) != 1) {
        cli::cli_abort("{name}: only one window can be provided, please see examples.")
      }
      if (is.null(names(intersect[[k]]$window))) {
        names(intersect[[k]]$window) <- getWindowName(intersect[[k]]$window)
      } else if (names(intersect[[k]]$window) == "") {
        names(intersect[[k]]$window) <- getWindowName(intersect[[k]]$window)
      }
    } else {
      cli::cli_abort("{name}: please provide window argument.")
    }

    if ("conceptSet" %in% nams) {
      intersect[[k]]$conceptSet <- omopgenerics::validateConceptSetArgument(intersect[[k]]$conceptSet)
    }

    # add names if missing
    if (namesIntersect[k] == "") {
      if ("tableName" %in% nams) {
        tblName <- intersect[[k]]$tableName
      } else if ("conceptSet" %in% nams) {
        tblName <- "Concepts"
      } else {
        tblName <- intersect[[k]]$targetCohortTable
      }
      value <- name |>
        as.character() |>
        getValue()
      winName <- getWindowNames(intersect[[k]]$window)
      namesIntersect[k] <- paste(tblName, value, winName)
    }
  }

  names(intersect) <- namesIntersect

  return(invisible(intersect))
}
getWindowNames <- function(window) {
  getname <- function(element) {
    element <- tolower(as.character(element))
    element <- gsub("-", "m", element)
    invisible(paste0(element[1], "_to_", element[2]))
  }
  windowNames <- names(window)
  if (is.null(windowNames)) {
    windowNames <- lapply(window, getname)
  } else {
    windowNames[windowNames == ""] <- lapply(window[windowNames == ""], getname)
  }
  invisible(windowNames)
}
getWindowName <- function(win) {
  paste0(win[[1]][1], " to ", win[[1]][2])
}
