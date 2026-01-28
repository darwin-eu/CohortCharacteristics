
#' Helper for consistent documentation of `result`.
#'
#' @param result A summarised_result object.
#'
#' @name resultDoc
#' @keywords internal
NULL

#' Helper for consistent documentation of `table`.
#'
#' @param type Character string specifying the desired output table format. See
#' `visOmopResults::tableType()` for supported table types. If type = `NULL`,
#' global options (set via `visOmopResults::setGlobalTableOptions()`) will be
#' used if available; otherwise, a default 'gt' table is created.
#' @param header Columns to use as header. See options with
#' `availableTableColumns(result)`.
#' @param groupColumn Columns to group by. See options with
#' `availableTableColumns(result)`.
#' @param hide Columns to hide from the visualisation. See options with
#' `availableTableColumns(result)`.
#' @param style Defines the visual formatting of the table. This argument can
#' be provided in one of the following ways:
#' 1. **Pre-defined style**: Use the name of a built-in style (e.g., "darwin").
#' See `visOmopResults::tableStyle()` for available options.
#' 2. **YAML file path**: Provide the path to an existing .yml file defining a
#' new style.
#' 3. **List of custome R code**: Supply a block of custom R code or a named
#' list describing styles for each table section. This code must be specific to
#' the selected table type.
#'
#' If style = `NULL`, the function will use global
#' options (see `visOmopResults::setGlobalTableOptions()`) or an existing
#' `_brand.yml` file (if found); otherwise, the default style is applied. For
#' more details, see the *Styles* vignette in **visOmopResults** website.
#' @param .options A named list with additional formatting options.
#' `visOmopResults::tableOptions()` shows allowed arguments and their default
#' values.
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
#' @param style Visual theme to apply. Character, or `NULL`. If a character, this
#' may be either the name of a built-in style (see `plotStyle()`), or a path to
#' a `.yml` file that defines a custom style. If NULL, the function will use the
#' explicit default style, unless a global style option is set (see
#' `setGlobalPlotOptions()`), or a _brand.yml file is present (in that order).
#' Refer to the package vignette on styles to learn more.
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
