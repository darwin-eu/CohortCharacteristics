
#' Helper for consistent documentation of `result`.
#'
#' @param result A summarised_result object.
#'
#' @name resultDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `table`.
#'
#' @param type Type of table. Check supported types with
#' `visOmopResults::tableType()`.
#' @param header Columns to use as header. See options with
#' `availableTableColumns(result)`.
#' @param groupColumn Columns to group by. See options with
#' `availableTableColumns(result)`.
#' @param hide Columns to hide from the visualisation. See options with
#' `availableTableColumns(result)`.
#'
#' @name tableDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `plot`.
#'
#' @param facet Columns to facet by. See options with
#' `availablePlotColumns(result)`. Formula is also allowed to specify rows and
#' columns.
#' @param colour Columns to color by. See options with
#' `availablePlotColumns(result)`.
#'
#' @name plotDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `uniqueCombinations`.
#'
#' @param uniqueCombinations Whether to restrict to unique reference and
#' comparator comparisons.
#'
#' @name uniqueCombinationsDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `cohort`.
#'
#' @param cohort A cohort_table object.
#'
#' @name cohortDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `cohortId`.
#'
#' @param cohortId A cohort definition id to restrict by. If NULL, all cohorts
#' will be included.
#'
#' @name cohortIdDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `strata`.
#'
#' @param strata A list of variables to stratify results. These variables
#' must have been added as additional columns in the cohort table.
#'
#' @name strataDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `timeScale`.
#'
#' @param timeScale Time scale to show, it can be "days" or "years".
#'
#' @name timeScaleDoc
#' @keywords internal
NULL
