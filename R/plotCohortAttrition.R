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
#' @param type type of the output, it can either be: 'htmlwidget', 'png', or
#' 'DiagrammeR'.
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
#' library(clock)
#'
#' cdm <- mockCohortCharacteristics(numberIndividuals = 1000)
#'
#' cdm[["cohort1"]] <- cdm[["cohort1"]] |>
#'   filter(get_year(cohort_start_date) >= 2000) |>
#'   recordCohortAttrition("Restrict to cohort_start_date >= 2000") |>
#'   filter(get_year(cohort_end_date) < 2020) |>
#'   recordCohortAttrition("Restrict to cohort_end_date < 2020") |>
#'   compute(temporary = FALSE, name = "cohort1")
#'
#' result <- summariseCohortAttrition(cdm$cohort1)
#'
#' result |>
#'   filter(group_level == "cohort_2") |>
#'   plotCohortAttrition()
#'
#' }
#'
plotCohortAttrition <- function(result,
                                show = c("subjects", "records"),
                                type = "htmlwidget",
                                cohortId = lifecycle::deprecated()) {
  if (lifecycle::is_present(cohortId)) {
    lifecycle::deprecate_soft("0.3.0", "plotCohortAttrition(cohortId = )")
  }
  rlang::check_installed("DiagrammeR")
  omopgenerics::assertChoice(show, choices = c("subjects", "records"), unique = TRUE)
  omopgenerics::assertChoice(type, c("htmlwidget", "html", "png", "svg", "DiagrammeR"), length = 1)

  if (length(show) == 0) {
    cli::cli_warn("`show` can not be empty")
    graph <- emptyDiagram("No variable to be displayed. `show` can not be empty.")
  } else {
    if (inherits(result, "cohort_table")) {
      cli::cli_abort(c(
        x = "{.cls cohort_table} objects not accepted as inputs for `plotCohortAttrition()`",
        i = "Please use `cdm$cohort |> summariseCohortAttrition() |> plotCohortAttrition()` instead."
      ))
    }
    colsAttr <- omopgenerics::cohortColumns("cohort_attrition")
    if (inherits(result, "data.frame") && all(colsAttr %in% colnames(result))) {
      result <- result |>
        dplyr::select(dplyr::all_of(colsAttr)) |>
        summariseAttrition()
    }
    result <- omopgenerics::validateResultArgument(result)
    result <- result |>
      omopgenerics::filterSettings(
        .data$result_type == "summarise_cohort_attrition"
      )
    if (nrow(result) == 0) {
      cli::cli_warn("No attrition found in the results")
      graph <- emptyDiagram("No attrition found in the results")
    } else {
      checkVersion(result)

      # prepare the data
      data <- prepareData(result = result, show = show)

      # prepare the graph
      style <- defaultStyle()
      graph <- prepareGraph(data = data, style = style)
    }
  }

  # export result
  output <- exportGraph(graph = graph, type = type, n = length(data))

  if (type == "png") {
    invisible(output)
  } else {
    output
  }
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
    )
}
limitMessage <- function(x) {
  ncharlim <- 30
  purrr::map_chr(x, \(xx) {
    xx <- purrr::flatten_chr(strsplit(xx, split = " "))
    nc <- nchar(xx)
    mes <- character()
    k <- 0
    n <- Inf
    for (i in seq_along(xx)) {
      if (n + nc[i] + 1 <= ncharlim) {
        mes[k] <- paste0(mes[k], " ", xx[i])
        n <- n + nc[i]
      } else {
        k <- k + 1
        mes[k] <- xx[i]
        n <- nc[i]
      }
    }
    mes |>
      stringr::str_replace_all(pattern = "'", replacement = "\u00b4") |> # ' character is not supported and we substitute it with \u00b4
      paste0(collapse = "\n")
  })
}
prepareData <- function(result, show) {
  result |>
    dplyr::inner_join(
      omopgenerics::settings(result) |>
        dplyr::select("result_id", "min_cell_count"),
      by = "result_id"
    ) |>
    omopgenerics::splitAll() |>
    omopgenerics::pivotEstimates(
      pivotEstimatesBy = c("variable_name", "estimate_name"),
      nameStyle = "{variable_name}"
    ) |>
    dplyr::mutate(dplyr::across(
      dplyr::any_of(c("number_records", "number_subjects", "excluded_records", "excluded_subjects")),
      \(x) dplyr::if_else(is.na(x), paste0("<", .data$min_cell_count), prettyNum(x, big.mark = ","))
    )) |>
    dplyr::select(!c("variable_level", "min_cell_count", "result_id")) |>
    dplyr::group_by(.data$cdm_name, .data$cohort_name) |>
    dplyr::group_split() |>
    as.list() |>
    purrr::map(\(x) {
      title <- paste0("Database: ", unique(x$cdm_name), "\nCohort name: ", unique(x$cohort_name))
      x <- x |>
        dplyr::mutate(reason_id = as.integer(.data$reason_id)) |>
        dplyr::arrange(.data$reason_id)
      reason <- limitMessage(x$reason)
      count <- purrr::map(show, \(sh) {
        limitMessage(paste0("N ", sh, " = ", x[[paste0("number_", sh)]]))
      }) |>
        purrr::reduce(paste, sep = "\n")
      x <- x |>
        dplyr::filter(.data$reason_id > 1L)
      exclude <- purrr::map(show, \(sh) {
        limitMessage(paste0("N ", sh, " = ", x[[paste0("excluded_", sh)]]))
      }) |>
        purrr::reduce(paste, sep = "\n")
      list(title = title, reason = reason, count = count, exclude = exclude)
    })
}
prepareGraph <- function(data, style) {
  graph <- DiagrammeR::create_graph()
  nodeId <- 0

  # calculate position of the nodes
  data <- boxesPosition(data, style)

  # create all diagrams
  for (k in seq_along(data)) {

    x <- data[[k]]

    # title box
    graph <- graph |>
      DiagrammeR::add_node(
        label = x$title,
        node_aes = DiagrammeR::node_aes(
          shape = "box",
          height = x$title_height,
          width = x$title_width,
          x = x$title_x,
          y = x$title_y,
          fontsize = style$fontsize_title,
          fontname = style$fontname_title,
          fontcolor = style$fontcolour_title,
          color = style$linecolour_title,
          fillcolor = style$backgroundcolour_title
        )
      )
    nodeId <- nodeId + 1

    # box of counts
    for (i in seq_along(x$count)) {
      # add box
      graph <- graph |>
        DiagrammeR::add_node(
          label = x$count[i],
          node_aes = DiagrammeR::node_aes(
            shape = "box",
            height = x$count_height[i],
            width = x$count_width[i],
            x = x$count_x[i],
            y = x$count_y[i],
            fontsize = style$fontsize_count,
            fontname = style$fontname_count,
            fontcolor = style$fontcolour_count,
            color = style$linecolour_count,
            fillcolor = style$backgroundcolour_count
          )
        )
      nodeId <- nodeId + 1

      # add arrow
      if (i > 1) {
        graph <- graph |>
          DiagrammeR::add_edge(
            from = nodeId - 1,
            to = nodeId,
            edge_aes = DiagrammeR::edge_aes(color = style$linecolour_arrow)
          )
      }
    }

    # box of reason and exclude
    for (i in seq_along(x$reason)) {
      graph <- graph |>
        # add reason
        DiagrammeR::add_node(
          label = x$reason[i],
          node_aes = DiagrammeR::node_aes(
            shape = "box",
            height = x$reason_height[i],
            width = x$reason_width[i],
            x = x$reason_x[i],
            y = x$reason_y[i],
            fontsize = style$fontsize_reason,
            fontname = style$fontname_reason,
            fontcolor = style$fontcolour_reason,
            color = style$linecolour_reason,
            fillcolor = style$backgroundcolour_reason
          )
        )
      nodeId <- nodeId + 1

      # add arrow
      if (i > 1) {
        graph <- graph |>
          # add exclude
          DiagrammeR::add_node(
            label = x$exclude[i-1],
            node_aes = DiagrammeR::node_aes(
              shape = "box",
              height = x$exclude_height[i-1],
              width = x$exclude_width[i-1],
              x = x$exclude_x[i-1],
              y = x$exclude_y[i-1],
              fontsize = style$fontsize_exclude,
              fontname = style$fontname_exclude,
              fontcolor = style$fontcolour_exclude,
              color = style$linecolour_exclude,
              fillcolor = style$backgroundcolour_exclude
            )
          ) |>
          # add arrow
          DiagrammeR::add_edge(
            from = nodeId,
            to = nodeId + 1,
            edge_aes = DiagrammeR::edge_aes(color = style$linecolour_arrow)
          )
        nodeId <- nodeId + 1
      }

    }

  }

  graph
}
exportGraph <- function(graph, type, n) {
  if (type != "DiagrammeR") {
    graph <- DiagrammeR::render_graph(graph)
    if (type == "png") {
      rlang::check_installed("DiagrammeRsvg")
      rlang::check_installed("rsvg")
      rlang::check_installed("grid")
      rlang::check_installed("png")
      svg <- DiagrammeRsvg::export_svg(graph)
      fileName <- tempfile(fileext = ".png")
      rsvg::rsvg_png(charToRaw(svg), fileName, width = n * 2000)
      img <- png::readPNG(fileName)
      graphics::plot.new()
      grid::grid.raster(img)
      graph <- img
      unlink(fileName)
    }
  }
  return(graph)
}
defaultStyle <- function() {
  list(
    line_height = 0.13,
    width_exclude = 1.2,
    width_reason = 2,
    width_count = 1.2,
    width_title = 1,
    width_arrow = 0.35,
    width_sep = 4,
    sep = 0.15,
    sep_title = 0,
    sep_reason = 0.13,
    sep_count = 0.13,
    sep_exclude = 0.13,
    backgroundcolour_reason = "#F0F8FF",
    backgroundcolour_count = "#FFFFFF",
    backgroundcolour_exclude = "#F8F8F8",
    backgroundcolour_title = "#FFFFFF",
    fontcolour_reason = "#000000",
    fontcolour_count = "#000000",
    fontcolour_exclude = "#000000",
    fontcolour_title = "#000000",
    fontsize_reason = 8,
    fontsize_count = 8,
    fontsize_exclude = 8,
    fontsize_title = 8,
    fontname_reason = "Calibri",
    fontname_count = "Calibri",
    fontname_exclude = "Calibri",
    fontname_title = "Calibri",
    linewidth_reason = 8,
    linewidth_count = 1,
    linewidth_exclude = 1,
    linewidth_arrow = 1,
    linecolour_reason = "#000000",
    linecolour_count = "#000000",
    linecolour_exclude = "#000000",
    linecolour_title = "#FFFFFF",
    linecolour_arrow = "#000000"
  )
}
boxesPosition <- function(data, style) {
  # TODO calculate as a function of fontname and fontsize
  lht <- style$line_height

  # calculate heights of all
  for (k in seq_along(data)) {
    # extract element
    x <- data[[k]]

    # title
    x$title_width <- style$width_title
    x$title_height <- style$sep_title + nlines(x$title) * lht
    x$title_x <- style$width_sep * (k - 1)
    x$title_y <- 0

    # position of reason, exclude and counts
    nr <- length(x$reason)
    x$reason_width <- rep(style$width_reason, nr)
    x$reason_x <- rep(style$width_sep * (k - 1), nr)
    x$exclude_width <- rep(style$width_exclude, nr)
    x$exclude_x <- rep(style$width_arrow + 0.5 * style$width_reason + 0.5 * style$width_exclude + style$width_sep * (k - 1), nr)
    x$count_width <- rep(style$width_count, nr)
    x$count_x <- rep(style$width_sep * (k - 1), nr)
    cum_y <- - 0.5 * x$title_height
    for (i in seq_len(nr)) {
      # reason
      x$reason_height[i] <- style$sep_reason + nlines(x$reason[i]) * lht
      x$reason_y[i] <- - style$sep + cum_y - 0.5 * x$reason_height[i]

      # exclude
      if (i > 1) {
        x$exclude_height[i-1] <- style$sep_exclude + nlines(x$exclude[i-1]) * lht
        x$exclude_y[i-1] <- x$reason_y[i]
      }

      # count
      x$count_height[i] <- style$sep_count + nlines(x$count[i]) * lht
      x$count_y[i] <- cum_y - 2 * style$sep - x$reason_height[i] - 0.5 * x$count_height[i]

      # update cum_y
      cum_y <- cum_y - 2 * style$sep - x$reason_height[i] - x$count_height[i]
    }

    # add it back
    data[[k]] <- x
  }

  return(data)
}
nlines <- function(x) {
  stringr::str_count(string = x, pattern = "\n") + 1
}
