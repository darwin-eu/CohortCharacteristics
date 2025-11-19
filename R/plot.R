
checkVersion <- function(result) {
  pkg <- "CohortCharacteristics"
  set <- omopgenerics::settings(result)
  version <- unique(set$package_version[set$package_name == pkg])
  installedVersion <- as.character(utils::packageVersion(pkg))
  difVersions <- version[!version %in% installedVersion]
  if (length(difVersions) > 0) {
    c("!" = "`result` was generated with a different version ({.strong {difVersions}}) of {.pkg {pkg}} than the one installed: {.strong {installedVersion}}") |>
      cli::cli_inform()
  }
  invisible()
}

plotInternal <- function(result,
                         resultType,
                         plotType,
                         facet,
                         colour,
                         uniqueCombinations = FALSE,
                         oneVariable = FALSE,
                         toYears = FALSE,
                         excludeGroup = character(),
                         x,
                         y,
                         style,
                         call = parent.frame()) {
  rlang::check_installed("visOmopResults")

  # check input
  result <- omopgenerics::validateResultArgument(result, call = call)
  omopgenerics::assertLogical(uniqueCombinations, length = 1, call = call)

  # resultType
  result <- result |>
    omopgenerics::filterSettings(.data$result_type %in% .env$resultType)
  if (nrow(result) == 0) {
    mes <- "No results found with `result_type == '{resultType}'`" |>
      glue::glue()
    cli::cli_warn(mes)
    return(emptyPlot(mes))
  }

  checkVersion(result)

  # one variable
  if (oneVariable) {
    vars <- unique(result$variable_name)
    if (length(vars) > 1) {
      mes <- "Multiple variables present: {.var {vars}}. Please subset to one of them." |>
        cli::cli_text() |>
        cli::cli_fmt(collapse = TRUE) |>
        stringr::str_replace(pattern = "\n", replacement = " ")
      cli::cli_warn(mes)
      return(emptyPlot(mes))
    }
  }

  # subset result
  if (plotType == "boxplot") {
    result <- result |>
      dplyr::filter(
        .data$estimate_name %in% c("min", "q25", "median", "q75", "max")
      )
    if (toYears) {
      result <- result |>
        dplyr::mutate(
          estimate_value = as.character(as.numeric(.data$estimate_value)/365)
        )
    }
  } else if (plotType == "densityplot") {
    result <- result |>
      dplyr::filter(.data$estimate_name %in% c("density_x", "density_y"))
    if (toYears) {
      result <- result |>
        dplyr::mutate(estimate_value = dplyr::if_else(
          .data$estimate_name == "density_x",
          as.character(as.numeric(.data$estimate_value)/365),
          as.character(as.numeric(.data$estimate_value)*365)
        ))
    }
  } else {
    result <- result |>
      dplyr::filter(.data$estimate_name %in% .env$y)
  }

  # uniqueCombinations
  if (uniqueCombinations) {
    result <- getUniqueCombinationsSr(result)
  }

  # notUniqueColumns
  notUnique <- notUniqueColumns(result)
  notUnique <- notUnique[!notUnique %in% excludeGroup]
  if (missing(x)) {
    x <- notUnique[!notUnique %in% c(colour, asCharacterFacet(facet))]
  }
  if (length(x) == 0) {
    result <- omopgenerics::tidy(result)
    x <- omopgenerics::uniqueId(exclude = colnames(result))
    result <- dplyr::mutate(result, !!x := "")
  }
  group <- notUnique
  if (length(group) == 0) {
    group <- NULL
  }

  # create plots
  if (plotType == "boxplot") {
    p <- visOmopResults::boxPlot(
      result = result,
      x = x,
      lower = "q25",
      middle = "median",
      upper = "q75",
      ymin = "min",
      ymax = "max",
      facet = facet,
      colour = colour,
      label = notUnique,
      style = style
    )
  } else if (plotType == "densityplot") {
    p <- visOmopResults::scatterPlot(
      result = result,
      x = "density_x",
      y = "density_y",
      line = TRUE,
      point = FALSE,
      ribbon = FALSE,
      ymin = NULL,
      ymax = NULL,
      facet = facet,
      colour = colour,
      group = group,
      label = notUnique,
      style = style
    )
  } else if (plotType == "scatterplot") {
    p <- visOmopResults::scatterPlot(
      result = result,
      x = x,
      y = y,
      line = FALSE,
      point = TRUE,
      ribbon = FALSE,
      ymin = NULL,
      ymax = NULL,
      facet = facet,
      colour = colour,
      group = group,
      label = notUnique,
      style = style
    )
  } else if (plotType == "barplot") {
    p <- visOmopResults::barPlot(
      result = result,
      x = x,
      y = y,
      facet = facet,
      colour = colour,
      label = notUnique,
      style = style
    )
  }

}
asCharacterFacet <- function(x) {
  if (rlang::is_formula(x)) {
    x <- as.character(x)
    x <- x[-1]
    x <- unlist(stringr::str_split(x, pattern = stringr::fixed(" + ")))
    x <- x[x != "."]
  }
  return(x)
}
notUniqueColumns <- function(result) {
  set <- omopgenerics::settings(result) |>
    dplyr::filter(.data$result_id %in% unique(.env$result$result_id)) |>
    dplyr::select(!c(
      "result_type", "package_name", "package_version", "group", "strata",
      "additional", "min_cell_count"
    ))
  result |>
    dplyr::select(
      "result_id", "cdm_name", "group_name", "group_level", "strata_name",
      "strata_level", "additional_name", "additional_level", "variable_level"
    ) |>
    dplyr::distinct() |>
    omopgenerics::splitAdditional() |>
    omopgenerics::splitGroup() |>
    omopgenerics::splitStrata() |>
    dplyr::left_join(set, by = "result_id") |>
    dplyr::select(!"result_id") |>
    purrr::map(unique) |>
    purrr::keep(\(x) length(x) > 1) |>
    names()
}
