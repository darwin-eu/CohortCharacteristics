
#' Available columns to use in `facet` and `colour` arguments in plot functions.
#'
#' @inheritParams resultDoc
#'
#' @return Character vector with the available columns.
#' @export
#'
#' @examples {
#' cdm <- mockCohortCharacteristics()
#'
#' result <- summariseCharacteristics(cdm$cohort1)
#'
#' availablePlotColumns(result)
#'
#' mockDisconnect(cdm)
#' }
availablePlotColumns <- function(result) {
  # initial checks
  result <- omopgenerics::validateResultArgument(result)

  # columns
  c("cdm_name",
    omopgenerics::groupColumns(result),
    omopgenerics::strataColumns(result),
    omopgenerics::additionalColumns(result),
    omopgenerics::settingsColumns(result),
    unique(result$estimate_name))
}

#' Available columns to use in `header`, `groupColumn` and `hide` arguments in
#' table functions.
#'
#' @inheritParams resultDoc
#'
#' @return Character vector with the available columns.
#' @export
#'
#' @examples {
#' cdm <- mockCohortCharacteristics()
#'
#' result <- summariseCharacteristics(cdm$cohort1)
#'
#' availableTableColumns(result)
#'
#' mockDisconnect(cdm)
#' }
availableTableColumns <- function(result) {
  # initial checks
  result <- omopgenerics::validateResultArgument(result)

  # columns
  c("cdm_name",
    omopgenerics::groupColumns(result),
    omopgenerics::strataColumns(result),
    omopgenerics::additionalColumns(result),
    omopgenerics::settingsColumns(result))
}

tableCohortCharacteristics <- function(result,
                                       resultType,
                                       header,
                                       groupColumn,
                                       hide,
                                       rename,
                                       modifyResults,
                                       estimateName,
                                       type,
                                       .options = list(),
                                       call = parent.frame()) {
  rlang::check_installed("visOmopResults")

  # check inputs
  result <- omopgenerics::validateResultArgument(result, call = call)

  # subset to rows of interest
  result <- result |>
    omopgenerics::filterSettings(.data$result_type == .env$resultType)
  if (nrow(result) == 0) {
    cli::cli_warn("There are no results with `result_type = {resultType}`")
    return(emptyTable(type))
  }

  checkVersion(result)

  set <- omopgenerics::settings(result)
  if (is.function(modifyResults)) {
    result <- do.call(modifyResults, list(x = result, call = call))
  }

  # settings columns
  ignore <- c(
    "result_id", "result_type", "package_name", "package_version", "group",
    "strata", "additional"
  )
  setColumns <- set |>
    dplyr::filter(.data$result_id %in% unique(.env$result$result_id)) |>
    purrr::map(\(x) x[!is.na(x)]) |>
    purrr::compact() |>
    names() |>
    purrr::discard(\(x) x %in% ignore)

  result |>
    dplyr::left_join(
      set |>
        dplyr::select("result_id", dplyr::all_of(setColumns)),
      by = "result_id"
    ) |>
    dplyr::mutate(estimate_value = dplyr::if_else(
      stringr::str_detect(.data$estimate_name, "count") & .data$estimate_value == "-",
      paste0("<", as.character(.data$min_cell_count)),
      .data$estimate_value
    )) |>
    dplyr::select(!c("result_id", "min_cell_count")) |>
    omopgenerics::splitAll() |>
    visOmopResults::visTable(
      estimateName = estimateName,
      header = header,
      rename = rename,
      type = type,
      hide = c("estimate_type", hide),
      groupColumn = groupColumn,
      .options = .options
    )
}
emptyTable <- function(type) {
  omopgenerics::emptySummarisedResult() |>
    visOmopResults::visOmopTable(type = type)
}
