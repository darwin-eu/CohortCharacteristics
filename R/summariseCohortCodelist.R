
#' Summarise the cohort codelist attribute
#'
#' `r lifecycle::badge('experimental')`
#'
#' @inheritParams cohortDoc
#' @inheritParams cohortIdDoc
#'
#' @return A summarised_result object with the exported cohort codelist
#' information.
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(dplyr, warn.conflicts = FALSE)
#' library(omock)
#' library(CDMConnector)
#'
#' cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#'
#' cdm <- generateConceptCohortSet(cdm = cdm,
#'                                 conceptSet = list(pharyngitis = 4112343L),
#'                                 name = "my_cohort")
#'
#' result <- summariseCohortCodelist(cdm$my_cohort)
#'
#' glimpse(result)
#'
#' tidy(result)
#' }
#'
summariseCohortCodelist <- function(cohort,
                                    cohortId = NULL) {
  # initial check
  cohort <- omopgenerics::validateCohortArgument(cohort)
  cohortId <- omopgenerics::validateCohortIdArgument(cohortId, cohort)

  set <- omopgenerics::settings(cohort)
  # extract codelists
  x <- cohortId |>
    purrr::map(\(ci) {
      cohortName <- set$cohort_name[set$cohort_definition_id == ci]
      c("index event", "inclusion criteria", "exit criteria") |>
        purrr::map(\(codelistType) {
          omopgenerics::cohortCodelist(cohort, cohortId = ci, codelistType = codelistType) |>
            suppressWarnings() |>
            purrr::map(\(x) dplyr::tibble(concept_id = as.integer(x))) |>
            dplyr::bind_rows(.id = "codelist_name") |>
            dplyr::mutate(cohort_name = .env$cohortName,
                          codelist_type = .env$codelistType)
        })
    }) |>
    dplyr::bind_rows()

  if (nrow(x) == 0) {
    result <- omopgenerics::emptySummarisedResult(settings = dplyr::tibble(
      result_id = 1L,
      result_type = "summarise_cohort_codelist",
      package_name = "CohortCharacteristics",
      package_version = pkgVersion()
    ))
    return(result)
  }

  # insert concepts
  nm <- omopgenerics::uniqueTableName()
  cdm <- omopgenerics::cdmReference(cohort) |>
    omopgenerics::insertTable(name = nm, table = x)

  # create result
  cdm[[nm]] |>
    dplyr::left_join(
      cdm$concept |>
        dplyr::select("concept_id", "concept_name"),
      by = "concept_id"
    ) |>
    dplyr::collect() |>
    dplyr::mutate(
      concept_name = dplyr::coalesce(.data$concept_name, "UNKNOWN CONCEPT"),
      cdm_name = omopgenerics::cdmName(cohort),
      variable_name = "overall",
      variable_level = "overall",
      result_type = "summarise_cohort_codelist",
      package_name = "CohortCharacteristics",
      package_version = pkgVersion()
    ) |>
    omopgenerics::transformToSummarisedResult(
      group = "cohort_name",
      strata = c("codelist_name", "codelist_type"),
      additional = "concept_name",
      estimates = "concept_id",
      settings = c("result_type", "package_name", "package_version")
    )
}

#' Create a visual table from `<summarised_result>` object from
#' `summariseCohortCodelist()`
#'
#' `r lifecycle::badge('experimental')`
#'
#' @inheritParams resultDoc
#' @param type Type of table. Supported types: "gt", "flextable", "tibble",
#' "datatable", "reactable".
#'
#' @return A visual table with the results.
#' @export
#'
#' @examples
#' \donttest{
#' library(CohortCharacteristics)
#' library(omock)
#' library(dplyr, warn.conflicts = FALSE)
#' library(CDMConnector)
#'
#' cdm <- mockCdmFromDataset(datasetName = "GiBleed", source = "duckdb")
#'
#' cdm <- generateConceptCohortSet(cdm = cdm,
#'                                 conceptSet = list(pharyngitis = 4112343L),
#'                                 name = "my_cohort")
#'
#' result <- summariseCohortCodelist(cdm$my_cohort)
#'
#' tableCohortCodelist(result)
#' }
#'
tableCohortCodelist <- function(result,
                                type = "reactable") {
  # check input
  result <- omopgenerics::validateResultArgument(result)
  omopgenerics::assertChoice(type, c("gt", "flextable", "tibble", "datatable", "reactable"))
  resultTypes <- omopgenerics::settings(result)$result_type

  # filter to interest results
  result <- result |>
    omopgenerics::filterSettings(.data$result_type == "summarise_cohort_codelist")

  # tidy
  result <- omopgenerics::tidy(result) |>
    dplyr::select(!c("variable_name", "variable_level"))

  if (nrow(result) == 0) {
    if (!"summarise_cohort_codelist" %in% resultTypes) {
      cli::cli_warn(c("x" = "No results found for {.pkg result_type == summarise_cohort_codelist}."))
    } else {
      cli::cli_warn(c("!" = "{.pkg result_type == summarise_cohort_codelist} results are empty."))
    }
    result <- dplyr::tibble(
      cdm_name = character(),
      cohort_name = character(),
      codelist_name = character(),
      codelist_type = character(),
      variable_name = character(),
      variable_level = character(),
      concept_name = character(),
      concept_id = integer()
    )
  }

  if (type == "gt") {
    rlang::check_installed("gt")
    result <- gt::gt(result)
  } else if (type == "flextable") {
    rlang::check_installed("flextable")
    result <- flextable::flextable(result)
  } else if (type == "datatable") {
    rlang::check_installed("DT")
    result <- DT::datatable(result, filter = "top", options = list(dom = "lrtip"))
  } else if (type == "reactable") {
    rlang::check_installed("reactable")
    result <- reactable::reactable(result, filterable = TRUE)
  }

  return(result)
}
