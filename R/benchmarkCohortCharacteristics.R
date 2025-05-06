
#' Benchmark the main functions of CohortCharacteristics package.
#'
#' @param cohort A cohort_table from a cdm_reference.
#' @param analysis Set of analysis to perform, must be a subset of: "count",
#' "attrition", "characteristics", "overlap", "timing" and
#' "large scale characteristics".
#'
#' @return A summarised_result object.
#' @export
#'
#' @examples
#' \dontrun{
#' CDMConnector::requireEunomia()
#' con <- duckdb::dbConnect(duckdb::duckdb(), CDMConnector::eunomiaDir())
#' cdm <- CDMConnector::cdmFromCon(
#'   con = con, cdmSchema = "main", writeSchema = "main"
#' )
#'
#' cdm <- CDMConnector::generateConceptCohortSet(
#'   cdm = cdm,
#'   conceptSet = list(sinusitis = 40481087, pharyngitis = 4112343),
#'   name = "my_cohort"
#' )
#'
#' benchmarkCohortCharacteristics(cdm$my_cohort)
#'
#' }
benchmarkCohortCharacteristics <- function(cohort,
                                           analysis = c("count", "attrition", "characteristics", "overlap", "timing", "large scale characteristics")) {
  # initial checks
  cohort <- omopgenerics::validateCohortArgument(cohort)
  omopgenerics::assertChoice(analysis, choices = c(
    "count", "attrition", "characteristics", "overlap", "timing",
    "large scale characteristics"), unique = TRUE)

  nPerson <- omopgenerics::cdmReference(cohort)$person |>
    dplyr::ungroup() |>
    dplyr::tally() |>
    dplyr::pull() |>
    as.character()

  set <- dplyr::tibble(
    result_id = 1L,
    result_type = "benchmark_cohort_characteristics",
    package_name = "CohortCharacteristics",
    package_version = pkgVersion(),
    cohort = dplyr::coalesce(omopgenerics::tableName(cohort), "temp"),
    source_type = omopgenerics::sourceType(.env$cohort),
    person_n = nPerson,
    !!!listCounts(cohort)
  )

  result <- dplyr::tibble(task = character(), time = numeric())

  if ("count" %in% analysis) {
    task <- "summariseCohortCount"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseCohortCount() |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))
  }

  if ("attrition" %in% analysis) {
    task <- "summariseCohortAttrition"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseCohortAttrition() |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))
  }

  if ("characteristics" %in% analysis) {
    task <- "summariseCharacteristics demographics"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseCharacteristics(
        counts = FALSE,
        demographics = TRUE
      ) |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))

    task <- "summariseCharacteristics number visits before"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseCharacteristics(
        counts = FALSE,
        demographics = FALSE,
        tableIntersectCount = list("Number visits" = list(
          tableName = "visit_occurrence", window = c(-Inf, 0)
        ))
      ) |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))

    task <- "summariseCharacteristics covariates before"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseCharacteristics(
        counts = FALSE,
        demographics = FALSE,
        cohortIntersectFlag = list("covariates before" = list(
          targetCohortTable = omopgenerics::tableName(cohort),
          window = c(-Inf, 0)
        ))
      ) |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))
  }

  if ("overlap" %in% analysis) {
    task <- "summariseCohortOverlap subjects"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseCohortOverlap() |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))

    task <- "summariseCohortOverlap subjects and cohort_start_date"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseCohortOverlap(overlapBy = c("subject_id", "cohort_start_date")) |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))
  }

  if ("timing" %in% analysis) {
    task <- "summariseCohortTiming no density"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseCohortTiming(estimates = c("min", "q25", "median", "q75", "max")) |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))

    task <- "summariseCohortTiming density"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseCohortTiming(estimates = c("density")) |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))
  }

  if ("large scale characteristics" %in% analysis) {
    windows <- list(c(-Inf, -1), c(0, 0), c(1, Inf))

    task <- "summariseLargeScaleCharacteristics event condition_occurrence"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseLargeScaleCharacteristics(
        window = windows,
        eventInWindow = "condition_occurrence"
      ) |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))

    task <- "summariseLargeScaleCharacteristics episode drug_exposure"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseLargeScaleCharacteristics(
        window = windows,
        episodeInWindow = "drug_exposure"
      ) |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))

    task <- "summariseLargeScaleCharacteristics source measurement"
    benchmarkMessage(task)
    t0 <- Sys.time()
    cohort |>
      summariseLargeScaleCharacteristics(
        window = windows,
        eventInWindow = "measurement",
        includeSource = TRUE
      ) |>
      suppressMessages() |>
      invisible()
    time <- as.numeric(Sys.time() - t0)
    result <- result |>
      dplyr::union_all(dplyr::tibble(task = task, time = time))
  }

  result |>
    omopgenerics::uniteGroup(cols = "task") |>
    omopgenerics::uniteStrata() |>
    omopgenerics::uniteAdditional() |>
    dplyr::mutate(
      result_id = 1L,
      cdm_name = omopgenerics::cdmName(cohort),
      variable_name = "overall",
      variable_level = "overall",
      estimate_name = "time_seconds",
      estimate_type = "numeric",
      estimate_value = as.character(round(.data$time, 3))
    ) |>
    dplyr::select(!"time") |>
    omopgenerics::newSummarisedResult(settings = set)
}
listCounts <- function(cohort) {
  counts <- omopgenerics::settings(cohort) |>
    dplyr::select("cohort_name", "cohort_definition_id") |>
    dplyr::left_join(
      omopgenerics::cohortCount(cohort) |>
        dplyr::select("cohort_definition_id", "number_records"),
      by = "cohort_definition_id"
    ) |>
    dplyr::mutate(number_records = dplyr::coalesce(.data$number_records, 0L))
  counts <- counts$number_records |>
    as.list() |>
    rlang::set_names(nm = counts$cohort_name)
  counts$total_counts <- sum(unlist(counts))
  purrr::map(counts, as.character)
}
benchmarkMessage <- function(msg, nm = NULL) {
  date <- format(Sys.time(), "%d-%m-%Y %H:%M:%S")
  msg <- paste0("{.pkg {date}} Benchmark ", msg) |>
    rlang::set_names(nm = nm)
  cli::cli_inform(msg)
}
