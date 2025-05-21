test_that("getUniqueCombinationsSr", {
  x <- dplyr::tibble(
    cohort_name_reference = c("b", "y", "k"),
    cohort_name_comparator = c("a", "x", "z")
  ) |>
    omopgenerics::uniteGroup(
      cols = c("cohort_name_reference", "cohort_name_comparator")
    )

  # expect no change
  expect_identical(x, getUniqueCombinationsSr(x))

  # expect pairs drop
  x <- dplyr::tibble(
    cohort_name_reference = c("b", "y", "a"),
    cohort_name_comparator = c("a", "x", "b")
  ) |>
    omopgenerics::uniteGroup(
      cols = c("cohort_name_reference", "cohort_name_comparator")
    )
  expect_identical(
    x |>
      omopgenerics::filterGroup(.data$cohort_name_reference != "a"),
    getUniqueCombinationsSr(x)
  )
})
