% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/summariseCohortCount.R
\name{summariseCohortCount}
\alias{summariseCohortCount}
\title{Summarise counts for cohorts in a cohort table}
\usage{
summariseCohortCount(cohort, cohortId = NULL, strata = list())
}
\arguments{
\item{cohort}{A cohort_table object.}

\item{cohortId}{A cohort definition id to restrict by. If NULL, all cohorts
will be included.}

\item{strata}{A list of variables to stratify results. These variables
must have been added as additional columns in the cohort table.}
}
\value{
A summary of counts of the cohorts in the cohort table.
}
\description{
Summarise counts for cohorts in a cohort table
}
\examples{
\donttest{
library(CohortCharacteristics)
library(dplyr, warn.conflicts = FALSE)

cdm <- mockCohortCharacteristics()

summariseCohortCount(cohort = cdm$cohort1) |>
  glimpse()

mockDisconnect(cdm)
}
}
