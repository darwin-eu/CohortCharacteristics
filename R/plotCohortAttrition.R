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

#' create a ggplot from the output of summariseLargeScaleCharacteristics.
#'
#' `r lifecycle::badge("experimental")`
#'
#' @inheritParams resultDoc
#' @param show Which variables to show in the attrition plot, it can be
#' 'subjects', 'records' or both.
#' @param cohortId deprecated.
#'
#' @return A `grViz` visualisation.
#'
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(omopgenerics)
#' library(dplyr, warn.conflicts = FALSE)
#'
#' cdm <- mockCohortCharacteristics(numberIndividuals = 1000)
#'
#' cdm[["cohort1"]] <- cdm[["cohort1"]] |>
#'   filter(year(cohort_start_date) >= 2000) |>
#'   recordCohortAttrition("Restrict to cohort_start_date >= 2000") |>
#'   filter(year(cohort_end_date) < 2020) |>
#'   recordCohortAttrition("Restrict to cohort_end_date < 2020") |>
#'   compute(temporary = FALSE, name = "cohort1")
#'
#' result <- summariseCohortAttrition(cdm$cohort1)
#'
#' result |>
#'   filter(group_level == "cohort_2") |>
#'   plotCohortAttrition()
#'
#' mockDisconnect(cdm)
#' }
#'
plotCohortAttrition <- function(result,
                                show = c("subjects", "records"),
                                cohortId = lifecycle::deprecated()) {
  if (lifecycle::is_present(cohortId)) {
    lifecycle::deprecate_soft("0.3.0", "plotCohortAttrition(cohortId = )")
  }
  rlang::check_installed("DiagrammeR")
  omopgenerics::assertChoice(show, choices = c("subjects", "records"), unique = TRUE)
  if (length(show) == 0) {
    cli::cli_warn("`show` can not be empty")
    return(emptyDiagram("No variable to be displayed. `show` can not be empty."))
  }

  if (inherits(result, "cohort_table")) {
    result <- summariseCohortAttrition(result)
  }
  colsAttr <- omopgenerics::cohortColumns("cohort_attrition")
  if (inherits(result, "data.frame") && all(colsAttr %in% colnames(result))) {
    result <- result |>
      dplyr::select(dplyr::all_of(colsAttr)) |>
      summariseAttrition()
  }
  result <- omopgenerics::validateResultArgument(result)
  result <- result |>
    visOmopResults::filterSettings(
      .data$result_type == "summarise_cohort_attrition"
    )
  if (nrow(result) == 0) {
    cli::cli_warn("No attrition found in the results")
    return(emptyDiagram("No attrition found in the results"))
  }
  nCohorts <- length(unique(result$group_level))
  if (nCohorts > 1) {
    return(
      emptyDiagram(paste0(nCohorts, " cohorts present in the result object, please subset to just one of them"))
    )
  }

  checkVersion(result)

  cNumb <- paste0("number_", show)
  cExcl <- paste0("excluded_", show)

  xn <- result |>
    visOmopResults::splitAll() |>
    visOmopResults::pivotEstimates(
      pivotEstimatesBy = c("variable_name", "estimate_name"),
      nameStyle = "{variable_name}"
    ) |>
    dplyr::select("reason_id", "reason", dplyr::all_of(c(cNumb, cExcl))) |>
    dplyr::mutate(reason_id = as.numeric(.data$reason_id)) |>
    dplyr::arrange(.data$reason_id) |>
    dplyr::mutate(
      dplyr::across(dplyr::everything(), as.character),
      dplyr::across(dplyr::all_of(c(cNumb, cExcl)), formatNum)
    ) |>
    createLabels(cNumb)

  y <- selectLabels(xn, cExcl)
  xn <- y$xn
  att <- y$att

  # Create graph
  n <- nrow(xn)
  xg <- DiagrammeR::create_graph()

  w1 <- getWidthMainBox(xn)

  if (nrow(xn) == 1) {
    xg <- getSingleNode(xg, xn, w1)
  } else {
    att <- validateReason(att)

    h2 <- getHeightMiddleBox(att)

    p1 <- getPositionMainBox(xn, n, h2)

    w2 <- getWidthMiddleBox(att)

    p2 <- getPositionMiddleBox(p1)

    xg <- getNodes(xn, att, n, xg, h2, w1, p1, w2, p2)
  }
  return(DiagrammeR::render_graph(xg))
}

emptyDiagram <- function(message) {
  DiagrammeR::create_graph() |>
    DiagrammeR::add_node(
      label = message,
      node_aes = DiagrammeR::node_aes(
        shape = "box",
        fontcolor = "black",
        fillcolor = "white",
        fontname = "Calibri",
        fontsize = 10,
        x = 1, y = 1,
        width = 4, penwidth = 0
      )
    ) |>
    DiagrammeR::render_graph()
}

formatNum <- function(col) {
  dplyr::if_else(
    !is.na(as.numeric(col)),
    gsub(" ", "", format(as.integer(col), big.mark = ",")),
    col
  )
}

createLabels <- function(x, cols) {
  subjectCol <- cols[grepl("subjects", cols)]
  recordsCol <- cols[grepl("records", cols)]
  if (length(subjectCol) == 0) {
    x <- x |>
      dplyr::mutate(label = paste0("N records = ", .data[[recordsCol]]))
  } else if (length(recordsCol) == 0) {
    x <- x |>
      dplyr::mutate(label = paste0("N subjects = ", .data[[subjectCol]]))
  } else {
    x <- x |>
      dplyr::mutate(label = paste0(
        "N subjects = ", .data[[subjectCol]], "\nN records = ",
        .data[[recordsCol]]
      ))
  }
  return(x)
}

selectLabels <- function(xn, cExcl) {
  if (nrow(xn) == 1) {
    xn <- xn |>
      dplyr::mutate(label = paste0("Qualifying events", "\n", .data$label)) |>
      dplyr::select("label")

    att <- NULL
  } else {
    att <- xn |>
      dplyr::filter(.data$reason_id > min(.data$reason_id)) |>
      createLabels(cExcl) |>
      dplyr::select("reason", "label")

    xn <- xn |>
      dplyr::mutate(reason_id = as.numeric(.data$reason_id)) |>
      dplyr::mutate(
        label = dplyr::if_else(
          .data$reason_id == min(.data$reason_id),
          paste0("Initial events", "\n", .data$label),
          dplyr::if_else(
            .data$reason_id == max(.data$reason_id),
            paste0("Final events", "\n", .data$label),
            .data$label
          )
        )
      ) |>
      dplyr::select("label")
  }
  return(list("xn" = xn, "att" = att))
}

getWidthMainBox <- function(xn) {
  return(0.08 * max(nchar(strsplit(xn$label[1], split = "\n")[[1]])))
}

getSingleNode <- function(xg, xn, w1) {
  k <- 1
  xn$label[k] <- gsub("Qualifying events", "Initial events", xn$label[k])
  xg <- xg %>%
    DiagrammeR::add_node(
      label = xn$label[k],
      node_aes = DiagrammeR::node_aes(
        shape = "box",
        x = 1,
        width = w1,
        y = 1,
        height = 0.6,
        fontsize = 11, fontcolor = "black",
        fontname = "Calibri",
        penwidth = 2,
        color = "black",
        fillcolor = "#F0F8FF"
      )
    )
}

getPositionMainBox <- function(xn, n, h2) {
  return(n + 1 - seq_len(n) - cumsum(append(0, h2 - 0.2)))
}

getPositionMiddleBox <- function(p1) {
  return((p1[1:(length(p1) - 1)] - p1[2:length(p1)]) / 2 + (p1[2:(length(p1))]))
}

validateReason <- function(att) {
  max_value <- 39

  n_char <- nchar(att$reason)
  n_char_count <- round(n_char / max_value)
  n_char_count[n_char_count > 1] <- n_char_count[n_char_count > 1]
  n_char_count[n_char_count == 1 & n_char < max_value] <- 0

  for (k in seq_len(nrow(att))) {
    cut <- seq_len(n_char_count[k])
    empty_positions <- stringr::str_locate_all(att$reason[k], " ") |>
      unlist() |>
      unique()

    if (n_char_count[k] != 0) {
      p <- stats::quantile(empty_positions, probs = seq_len(n_char_count[k]) / (n_char_count[k] + 1))
      matrix_positions <- matrix(empty_positions, length(cut), length(empty_positions), byrow = TRUE)
      positions <- unique(matrix_positions[seq_len(length(cut)), apply(abs(matrix_positions - p), 1, which.min)])
      for (kk in positions) {
        substr(att$reason[k], start = kk, stop = kk) <- "\n"
      }
    }
  }

  return(att)
}

getHeightMiddleBox <- function(att) {
  return((stringr::str_count(att$reason, pattern = "\n") + 1) * 0.2)
}

getWidthMiddleBox <- function(att) {
  return(min(2.25, 0.08 * max(nchar(unlist(strsplit(att$reason, "\n"))))))
}

getNodes <- function(xn, att, n, xg, h2, w1, p1, w2, p2) {
  for (k in seq_len(n)) {
    xg <- xg %>%
      DiagrammeR::add_node(
        label = xn$label[k],
        node_aes = DiagrammeR::node_aes(
          shape = "box",
          x = 1,
          width = w1,
          y = p1[k] + ifelse(k == 1, 0.1, 0) + ifelse(k == n, -0.1, 0),
          height = ifelse(k == 1 | k == n, 0.6, 0.4),
          fontsize = 11, fontcolor = "black",
          fontname = "Calibri",
          penwidth = ifelse(k == 1 | k == n, 2, 1),
          color = "black",
          fillcolor = "#F0F8FF"
        )
      )
    if (k > 1) {
      xg <- xg %>%
        DiagrammeR::add_edge(from = k - 1, to = k, edge_aes = DiagrammeR::edge_aes(color = "black"))
    }
  }

  if (n > 1) {
    for (k in seq_len(nrow(att))) {
      xg <- xg %>%
        DiagrammeR::add_node(
          label = att$label[k],
          node_aes = DiagrammeR::node_aes(
            shape = "box",
            x = 3,
            width = 1.2,
            y = p2[k],
            height = 0.4,
            fontsize = 9,
            fillcolor = "grey",
            fontcolor = "black",
            color = "black",
            fontname = "Calibri"
          )
        ) %>%
        DiagrammeR::add_node(
          label = att$reason[k],
          node_aes = DiagrammeR::node_aes(
            shape = "box",
            x = 1,
            width = w2,
            y = p2[k],
            height = h2[k],
            fillcolor = "white",
            color = "black",
            fontcolor = "back",
            fontname = "Calibri",
            fontsize = 10
          )
        ) %>%
        DiagrammeR::add_edge(
          from = 2 * k + n, to = 2 * k + n - 1, edge_aes = DiagrammeR::edge_aes(color = "black")
        )
    }
  }
  return(xg)
}
